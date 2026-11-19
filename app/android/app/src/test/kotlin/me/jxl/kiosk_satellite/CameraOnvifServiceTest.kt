package me.jxl.kiosk_satellite

import java.net.Socket
import java.security.MessageDigest
import java.text.SimpleDateFormat
import java.util.Base64
import java.util.Date
import java.util.TimeZone
import org.junit.Assert.*
import org.junit.Test

class CameraOnvifServiceTest {
    private fun service(
        auth: Boolean = false,
        tls: Boolean = false,
        audio: Boolean = false,
        deviceName: String = "Kiosk Satellite",
        networkInfo: (String) -> CameraOnvifService.NetworkInfo? = {
            CameraOnvifService.NetworkInfo("wlan0", true, null, 1500)
        },
    ) = CameraOnvifService(
        1280, 720, 15, 800_000, audio, if (auth) "viewer" else null, "secret",
        { Base64.getEncoder().encodeToString(it) }, { Base64.getDecoder().decode(it) }, "device-id", "test&version", networkInfo, deviceName, tls,
    )

    private fun request(operation: String, header: String = "") = """
        <s:Envelope xmlns:s="${CameraOnvifService.SOAP}" xmlns:tds="${CameraOnvifService.DEVICE}"
          xmlns:trt="${CameraOnvifService.MEDIA}" xmlns:tt="${CameraOnvifService.SCHEMA}">
          <s:Header>$header</s:Header><s:Body>$operation</s:Body>
        </s:Envelope>
    """.trimIndent().toByteArray()

    private fun response(service: CameraOnvifService, operation: String, header: String = ""): CameraOnvifService.Response =
        service.respond(if (operation.startsWith("<tds:")) "/onvif/device_service" else "/onvif/media_service",
            request(operation, header), "192.168.1.5", 8554)

    @Test fun profilesExposeSharedSettingsAndAudioIsOptional() {
        val off = response(service(), "<trt:GetProfiles/>")
        assertEquals("200 OK", off.status)
        assertTrue(off.body.contains("<tt:Width>1280</tt:Width>"))
        assertTrue(off.body.contains("<tt:FrameRateLimit>15</tt:FrameRateLimit>"))
        assertTrue(off.body.contains("<tt:BitrateLimit>800</tt:BitrateLimit>"))
        assertFalse(off.body.contains("AudioEncoderConfiguration"))
        val on = response(service(audio = true), "<trt:GetProfiles/>").body
        assertTrue(on.contains("<tt:Encoding>AAC</tt:Encoding>"))
        assertTrue(on.contains("<tt:Bitrate>32</tt:Bitrate>"))
        assertTrue(on.indexOf("AudioSourceConfiguration") < on.indexOf("VideoEncoderConfiguration"))
        CameraOnvifService.parse(on.toByteArray())
    }

    @Test fun videoChangesUpdateTheExistingOnvifProfile() {
        val service = service()
        service.updateVideo(1920, 1080, 25, 2_000_000)
        val profile = response(service, "<trt:GetProfiles/>").body
        assertTrue(profile.contains("<tt:Width>1920</tt:Width>"))
        assertTrue(profile.contains("<tt:Height>1080</tt:Height>"))
        assertTrue(profile.contains("<tt:FrameRateLimit>25</tt:FrameRateLimit>"))
        assertTrue(profile.contains("<tt:BitrateLimit>2000</tt:BitrateLimit>"))
        assertTrue(response(service, "<trt:GetVideoSources/>").body.contains("<tt:Width>1920</tt:Width>"))
    }

    @Test fun profileReportsTheEncoderProfileFromTheStream() {
        var saved: String? = null
        val s = CameraOnvifService(
            1280, 720, 15, 800_000, false, null, "secret",
            { Base64.getEncoder().encodeToString(it) }, { Base64.getDecoder().decode(it) }, "device-id", "1",
            h264Profile = "Main", onH264Profile = { saved = it },
        )
        assertTrue(response(s, "<trt:GetProfiles/>").body.contains("<tt:H264Profile>Main</tt:H264Profile>"))
        s.updateParameterSet(byteArrayOf(0x67, 0x64, 0x00, 0x28))
        assertEquals("High", saved)
        assertTrue(response(s, "<trt:GetVideoEncoderConfigurations/>").body.contains("<tt:H264Profile>High</tt:H264Profile>"))
        saved = null
        s.updateParameterSet(byteArrayOf(0x67, 0x64, 0x00, 0x1f))
        s.updateParameterSet(byteArrayOf(0x68, 0x42, 0x00, 0x1f))
        assertNull(saved)
        assertEquals("Baseline", CameraOnvifService.h264ProfileOf(byteArrayOf(0x67, 0x42, 0xC0.toByte(), 0x1f)))
        assertEquals("Main", CameraOnvifService.h264ProfileOf(byteArrayOf(0x67, 0x4D, 0x00, 0x1f)))
        assertNull(CameraOnvifService.h264ProfileOf(byteArrayOf(0x67, 0x53)))
        assertNull(CameraOnvifService.h264ProfileOf(byteArrayOf(0x67)))
    }

    @Test fun responsesNameTheOperationAndFault() {
        val s = service()
        val ok = response(s, "<trt:GetProfiles/>")
        assertEquals("GetProfiles", ok.operation)
        assertNull(ok.fault)
        val udp = response(s, streamRequest().replace(">RTSP<", ">UDP<"))
        assertEquals("GetStreamUri", udp.operation)
        assertEquals("ter:InvalidStreamSetup: Use RTP-Unicast with RTSP transport", udp.fault)
    }

    @Test fun encoderOptionsListTheCurrentStreamSettings() {
        val s = service()
        s.updateParameterSet(byteArrayOf(0x67, 0x64, 0x00, 0x28))
        for (request in listOf("<trt:GetVideoEncoderConfigurationOptions/>",
            "<trt:GetVideoEncoderConfigurationOptions><trt:ConfigurationToken>video_encoder</trt:ConfigurationToken></trt:GetVideoEncoderConfigurationOptions>",
            "<trt:GetVideoEncoderConfigurationOptions><trt:ProfileToken>camera</trt:ProfileToken></trt:GetVideoEncoderConfigurationOptions>")) {
            val options = response(s, request)
            assertEquals("200 OK", options.status)
            assertTrue(options.body.contains("<tt:ResolutionsAvailable><tt:Width>1280</tt:Width><tt:Height>720</tt:Height></tt:ResolutionsAvailable>"))
            assertTrue(options.body.contains("<tt:FrameRateRange><tt:Min>15</tt:Min><tt:Max>15</tt:Max></tt:FrameRateRange>"))
            assertTrue(options.body.contains("<tt:H264ProfilesSupported>High</tt:H264ProfilesSupported>"))
            CameraOnvifService.parse(options.body.toByteArray())
        }
        assertTrue(response(s, "<trt:GetVideoEncoderConfigurationOptions><trt:ConfigurationToken>other</trt:ConfigurationToken>" +
            "</trt:GetVideoEncoderConfigurationOptions>").body.contains("ter:NoConfig"))
        assertTrue(response(s, "<trt:GetVideoEncoderConfigurationOptions><trt:ProfileToken>other</trt:ProfileToken>" +
            "</trt:GetVideoEncoderConfigurationOptions>").body.contains("ter:NoProfile"))
    }

    @Test fun deviceServicesAndStreamUseTheSharedPort() {
        val s = service()
        val services = response(s, "<tds:GetServices><tds:IncludeCapability>true</tds:IncludeCapability></tds:GetServices>")
        assertTrue(services.body.contains("http://192.168.1.5:8554/onvif/media_service"))
        assertTrue(services.body.contains("SnapshotUri=\"true\""))
        assertFalse(services.body.contains("<tds:Namespace>${CameraOnvifService.EVENTS}</tds:Namespace>"))
        val info = response(s, "<tds:GetDeviceInformation/>")
        assertTrue(info.body.contains("test&amp;version"))
        val uri = response(s, streamRequest())
        assertEquals("200 OK", uri.status)
        assertTrue(uri.body.contains("rtsp://192.168.1.5:8554/camera"))
        assertTrue(response(s, streamRequest("missing")).body.contains("ter:NoProfile"))
        assertTrue(response(s, streamRequest().replace(">RTSP<", ">UDP<")).body.contains("ter:InvalidStreamSetup"))
        assertTrue(response(s, "<trt:SetVideoEncoderConfiguration/>").body.contains("ter:ActionNotSupported"))
    }

    @Test fun snapshotUriPointsAtTheSharedPort() {
        fun snapshot(profile: String = "camera") = "<trt:GetSnapshotUri><trt:ProfileToken>$profile</trt:ProfileToken></trt:GetSnapshotUri>"
        val plain = response(service(), snapshot())
        assertEquals("200 OK", plain.status)
        assertEquals("GetSnapshotUri", plain.operation)
        val document = CameraOnvifService.parse(plain.body.toByteArray())
        assertEquals("http://192.168.1.5:8554/onvif/snapshot",
            document.getElementsByTagNameNS(CameraOnvifService.SCHEMA, "Uri").item(0).textContent)
        assertTrue(response(service(), snapshot("missing")).body.contains("ter:NoProfile"))
        val secure = service(auth = true, tls = true)
        assertTrue(response(secure, snapshot()).body.contains("ter:NotAuthorized"))
        assertTrue(response(secure, snapshot(), token()).body.contains("<tt:Uri>https://192.168.1.5:8554/onvif/snapshot</tt:Uri>"))
        assertTrue(response(service(), "<trt:GetServiceCapabilities/>").body.contains("SnapshotUri=\"true\""))
    }

    @Test fun snapshotEndpointServesJpegBehindDigest() {
        val jpeg = byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 1, 2, 3, 0xFF.toByte(), 0xD9.toByte())
        val snapshot = CameraOnvifSnapshot("viewer", "secret", { done -> done(jpeg, null) })
        val server = CameraRtspServer(0, "viewer", "secret", { "" }, {}, {}, onvif = service(auth = true), snapshot = snapshot)
        fun get(authorization: String? = null, method: String = "GET"): Pair<String, ByteArray> =
            Socket("127.0.0.1", server.localPort).use { socket ->
                socket.soTimeout = 2000
                socket.getOutputStream().write(("$method /onvif/snapshot HTTP/1.1\r\nHost: 127.0.0.1\r\n" +
                    (authorization?.let { "Authorization: $it\r\n" } ?: "") + "\r\n").toByteArray())
                val bytes = socket.getInputStream().readBytes()
                val split = String(bytes, Charsets.ISO_8859_1).indexOf("\r\n\r\n")
                String(bytes, 0, split, Charsets.ISO_8859_1) to bytes.copyOfRange(split + 4, bytes.size)
            }
        try {
            val (challengeHead, _) = get()
            assertTrue(challengeHead.startsWith("HTTP/1.1 401 Unauthorized"))
            val nonce = Regex("nonce=\"([^\"]+)\"").find(challengeHead)!!.groupValues[1]
            assertTrue(challengeHead.contains("qop=\"auth\""))
            val (head, body) = get(digest("GET", "/onvif/snapshot", nonce, qop = true))
            assertTrue(head, head.startsWith("HTTP/1.1 200 OK"))
            assertTrue(head.contains("Content-Type: image/jpeg"))
            assertArrayEquals(jpeg, body)
            assertTrue(get(digest("GET", "/onvif/snapshot", nonce)).first.startsWith("HTTP/1.1 200 OK"))
            val (headOnly, empty) = get(digest("HEAD", "/onvif/snapshot", nonce), "HEAD")
            assertTrue(headOnly.contains("Content-Length: ${jpeg.size}"))
            assertEquals(0, empty.size)
            assertTrue(get(digest("GET", "/onvif/snapshot", nonce, password = "wrong")).first.startsWith("HTTP/1.1 401"))
            assertTrue(get(digest("GET", "/onvif/snapshot", "0-forged")).first.startsWith("HTTP/1.1 401"))
            assertTrue(get(digest("POST", "/onvif/snapshot", nonce), "POST").first.startsWith("HTTP/1.1 405"))
        } finally { server.close() }
    }

    private fun digest(method: String, uri: String, nonce: String, password: String = "secret", qop: Boolean = false): String {
        fun md5(text: String) = MessageDigest.getInstance("MD5").digest(text.toByteArray()).joinToString("") { "%02x".format(it) }
        val ha1 = md5("viewer:Kiosk Satellite:$password")
        val ha2 = md5("$method:$uri")
        return if (qop) "Digest username=\"viewer\", realm=\"Kiosk Satellite\", nonce=\"$nonce\", uri=\"$uri\", " +
            "qop=auth, nc=00000001, cnonce=\"abc\", response=\"${md5("$ha1:$nonce:00000001:abc:auth:$ha2")}\", algorithm=MD5"
        else "Digest username=\"viewer\", realm=\"Kiosk Satellite\", nonce=\"$nonce\", uri=\"$uri\", response=\"${md5("$ha1:$nonce:$ha2")}\""
    }

    @Test fun encryptedServicesAdvertiseHttpsAndRtspsAndKeepAuthentication() {
        val s = service(auth = true, tls = true)
        assertTrue(response(s, "<tds:GetServices/>").body.contains("ter:NotAuthorized"))
        val services = response(s, "<tds:GetServices><tds:IncludeCapability>true</tds:IncludeCapability></tds:GetServices>", token()).body
        assertTrue(services.contains("https://192.168.1.5:8554/onvif/device_service"))
        assertTrue(services.contains("https://192.168.1.5:8554/onvif/media_service"))
        assertTrue(services.contains("TLS1.2=\"true\""))
        val capabilities = response(s, "<tds:GetCapabilities/>", token()).body
        assertTrue(capabilities.contains("<tt:TLS1.2>true</tt:TLS1.2>"))
        assertTrue(capabilities.contains("https://192.168.1.5:8554/onvif/media_service"))
        assertTrue(response(s, streamRequest(), token()).body.contains("rtsps://192.168.1.5:8554/camera"))
        assertTrue(response(service(), "<tds:GetCapabilities/>").body.contains("<tt:TLS1.2>false</tt:TLS1.2>"))
    }

    @Test fun homeAssistantCanReadInterfacesAndFallBackToTheStableSerial() {
        val hiddenMac = service(auth = true)
        assertTrue(response(hiddenMac, "<tds:GetNetworkInterfaces/>").body.contains("ter:NotAuthorized"))
        val network = response(hiddenMac, "<tds:GetNetworkInterfaces/>", token())
        assertEquals("200 OK", network.status)
        val document = CameraOnvifService.parse(network.body.toByteArray())
        assertEquals("true", document.getElementsByTagNameNS(CameraOnvifService.SCHEMA, "Enabled").item(0).textContent)
        assertEquals("", document.getElementsByTagNameNS(CameraOnvifService.SCHEMA, "HwAddress").item(0).textContent)
        val info = response(hiddenMac, "<tds:GetDeviceInformation/>", token())
        assertTrue(info.body.contains("<tds:SerialNumber>device-id</tds:SerialNumber>"))
        assertEquals("200 OK", response(hiddenMac, "<trt:GetProfiles/>", token()).status)
        assertEquals("200 OK", response(hiddenMac, streamRequest(), token()).status)

        val visibleMac = service(networkInfo = { host ->
            assertEquals("192.168.1.5", host)
            CameraOnvifService.NetworkInfo("eth&0", true, "AA:BB:CC:DD:EE:FF", null)
        })
        val visible = response(visibleMac, "<tds:GetNetworkInterfaces/>")
        assertTrue(visible.body.contains("<tt:HwAddress>AA:BB:CC:DD:EE:FF</tt:HwAddress>"))
        assertTrue(visible.body.contains("token=\"eth&amp;0\""))
        assertFalse(visible.body.contains("<tt:MTU>"))
        assertTrue(response(service(networkInfo = { null }), "<tds:GetNetworkInterfaces/>").body.contains("not implemented"))
    }

    @Test fun privateOrInvalidHardwareAddressesNeverBecomeDeviceIdentities() {
        assertNull(CameraOnvifService.readableMac(null))
        assertNull(CameraOnvifService.readableMac(byteArrayOf(2, 0, 0, 0, 0, 0)))
        assertNull(CameraOnvifService.readableMac(ByteArray(6)))
        assertNull(CameraOnvifService.readableMac(byteArrayOf(1, 2, 3, 4, 5, 6)))
        assertNull(CameraOnvifService.readableMac(ByteArray(8)))
        assertEquals("02:11:22:33:44:55", CameraOnvifService.readableMac(byteArrayOf(2, 17, 34, 51, 68, 85)))
    }

    @Test fun digestAuthenticationRejectsWrongPasswordsReplaysAndExpiredTokens() {
        val s = service(auth = true)
        assertEquals("200 OK", response(s, "<tds:GetSystemDateAndTime/>").status)
        assertTrue(response(s, "<trt:GetProfiles/>").body.contains("ter:NotAuthorized"))
        assertTrue(response(s, "<trt:GetProfiles/>", token(password = "wrong")).body.contains("ter:NotAuthorized"))
        assertTrue(response(s, "<trt:GetProfiles/>", token(time = System.currentTimeMillis() - 600_000)).body.contains("ter:NotAuthorized"))
        val valid = token()
        assertEquals("200 OK", response(s, "<trt:GetProfiles/>", valid).status)
        assertTrue(response(s, "<trt:GetProfiles/>", valid).body.contains("ter:NotAuthorized"))
    }

    @Test fun malformedSoapAndExternalEntitiesAreRejected() {
        val s = service()
        assertEquals("400 Bad Request", s.respond("/onvif/device_service", "<!DOCTYPE x [<!ENTITY e SYSTEM 'file:///etc/passwd'>]><x>&e;</x>".toByteArray(), "localhost", 8554).status)
        assertEquals("400 Bad Request", response(s, "<trt:GetProfiles/><trt:GetProfiles/>").status)
        assertEquals("404 Not Found", s.respond("/elsewhere", byteArrayOf(), "localhost", 8554).status)
        val wrongNamespace = request("<tds:GetDeviceInformation/>").toString(Charsets.UTF_8).replace(CameraOnvifService.DEVICE, "urn:wrong")
        assertTrue(s.respond("/onvif/device_service", wrongNamespace.toByteArray(), "localhost", 8554).body.contains("ter:ActionNotSupported"))
    }

    @Test fun httpAndRtspShareOneListenerWithoutStartingCameraForSoap() {
        val server = CameraRtspServer(0, null, "", { Base64.getEncoder().encodeToString(it) }, {}, {}, onvif = service())
        try {
            Socket("127.0.0.1", server.localPort).use { socket ->
                socket.soTimeout = 2000
                val bytes = request("<trt:GetProfiles/>")
                socket.getOutputStream().write(("POST /onvif/media_service HTTP/1.1\r\nHost: localhost\r\n" +
                    "Content-Length: ${bytes.size}\r\n\r\n").toByteArray() + bytes)
                val response = socket.getInputStream().readBytes().toString(Charsets.UTF_8)
                assertTrue(response.startsWith("HTTP/1.1 200 OK"))
                assertTrue(response.contains("GetProfilesResponse"))
                assertFalse(server.demand)
                assertEquals(0, server.clientCount)
            }
            Socket("127.0.0.1", server.localPort).use { socket ->
                socket.soTimeout = 2000
                socket.getOutputStream().write("OPTIONS * RTSP/1.0\r\nCSeq: 1\r\n\r\n".toByteArray())
                assertEquals("RTSP/1.0 200 OK", socket.getInputStream().bufferedReader().readLine())
            }
        } finally { server.close() }
        // Switching back to RTSP removes the HTTP service and releases the port.
        val rtspOnly = CameraRtspServer(server.localPort.coerceAtLeast(0), null, "", { "" }, {}, {})
        try {
            Socket("127.0.0.1", rtspOnly.localPort).use { socket ->
                socket.soTimeout = 2000
                socket.getOutputStream().write("POST /onvif/device_service HTTP/1.1\r\nContent-Length: 0\r\n\r\n".toByteArray())
                assertEquals("HTTP/1.1 404 Not Found", socket.getInputStream().bufferedReader().readLine())
            }
        } finally { rtspOnly.close() }
    }

    @Test fun listenerLogsEachClientRequestOutcomeOnce() {
        val notes = java.util.concurrent.LinkedBlockingQueue<String>()
        val server = CameraRtspServer(0, null, "", { Base64.getEncoder().encodeToString(it) }, {}, {},
            onDiagnostic = { event, message, _ -> notes.add("$event: $message") }, onvif = service())
        try {
            repeat(2) {
                Socket("127.0.0.1", server.localPort).use { socket ->
                    socket.soTimeout = 2000
                    val bytes = request(streamRequest().replace(">RTSP<", ">UDP<"))
                    socket.getOutputStream().write(("POST /onvif/media_service HTTP/1.1\r\nUser-Agent: NVR\r\n" +
                        "Content-Length: ${bytes.size}\r\n\r\n").toByteArray() + bytes)
                    socket.getInputStream().readBytes()
                }
            }
            Socket("127.0.0.1", server.localPort).use { socket ->
                socket.soTimeout = 2000
                socket.getOutputStream().write("DESCRIBE rtsp://127.0.0.1/other RTSP/1.0\r\nCSeq: 2\r\n\r\n".toByteArray())
                assertEquals("RTSP/1.0 404 Not Found", socket.getInputStream().bufferedReader().readLine())
            }
            assertEquals("onvif request: client=127.0.0.1, operation=GetStreamUri, status=500 Internal Server Error, " +
                "fault=ter:InvalidStreamSetup: Use RTP-Unicast with RTSP transport, userAgent=NVR",
                notes.poll(2, java.util.concurrent.TimeUnit.SECONDS))
            assertEquals("rtsp request: client=127.0.0.1, method=DESCRIBE, path=/other, status=404 Not Found",
                notes.poll(2, java.util.concurrent.TimeUnit.SECONDS))
            assertNull(notes.poll(200, java.util.concurrent.TimeUnit.MILLISECONDS))
        } finally { server.close() }
    }

    @Test fun discoveryMatchesCameraTypesAndScopesAndCorrelatesReplies() {
        val discovery = CameraOnvifDiscovery("device-id", 8554)
        fun probe(types: String, scope: String = "") = """
          <s:Envelope xmlns:s="${CameraOnvifService.SOAP}" xmlns:a="${CameraOnvifDiscovery.ADDRESSING}"
            xmlns:d="${CameraOnvifDiscovery.DISCOVERY}" xmlns:dn="http://www.onvif.org/ver10/network/wsdl">
            <s:Header><a:Action>${CameraOnvifDiscovery.DISCOVERY}/Probe</a:Action><a:MessageID>urn:uuid:probe-id</a:MessageID></s:Header>
            <s:Body><d:Probe><d:Types>$types</d:Types><d:Scopes>$scope</d:Scopes></d:Probe></s:Body>
          </s:Envelope>
        """.trimIndent().toByteArray()
        val reply = discovery.probeReply(probe("dn:NetworkVideoTransmitter"), listOf("192.168.1.5"))!!
        assertTrue(reply.contains("<a:RelatesTo>urn:uuid:probe-id</a:RelatesTo>"))
        assertTrue(reply.contains("http://192.168.1.5:8554/onvif/device_service"))
        assertTrue(reply.contains("urn:uuid:device-id"))
        val secure = CameraOnvifDiscovery("device-id", 8554, tls = true)
        for (message in listOf(
            secure.probeReply(probe("dn:NetworkVideoTransmitter"), listOf("192.168.1.5"))!!,
            secure.announcement(listOf("192.168.1.5")),
        )) {
            val document = CameraOnvifService.parse(message.toByteArray())
            assertEquals("https://192.168.1.5:8554/onvif/device_service",
                document.getElementsByTagNameNS(CameraOnvifDiscovery.DISCOVERY, "XAddrs").item(0).textContent)
        }
        CameraOnvifService.parse(reply.toByteArray())
        assertNull(discovery.probeReply(probe("dn:Printer"), listOf("192.168.1.5")))
        assertNull(discovery.probeReply(probe("", "onvif://www.onvif.org/name/Other"), listOf("192.168.1.5")))
        assertNotNull(discovery.probeReply(probe("", "onvif://www.onvif.org/type"), listOf("192.168.1.5")))
        // Home Assistant searches with both this type and this scope.
        val haReply = discovery.probeReply(probe("dn:NetworkVideoTransmitter",
            "onvif://www.onvif.org/Profile/Streaming"), listOf("192.168.1.5"))
        assertNotNull(haReply)
        assertTrue(haReply!!.contains("onvif://www.onvif.org/Profile/Streaming"))
    }

    @Test fun configuredNameIsSharedByDeviceInformationProfilesAndDiscovery() {
        val name = "Kitchen & café / tablet"
        val service = service(deviceName = name)
        fun content(operation: String, namespace: String, tag: String) =
            CameraOnvifService.parse(response(service, operation).body.toByteArray())
                .getElementsByTagNameNS(namespace, tag).item(0).textContent
        assertEquals(name, content("<tds:GetDeviceInformation/>", CameraOnvifService.DEVICE, "Model"))
        assertEquals(name, content("<tds:GetHostname/>", CameraOnvifService.SCHEMA, "Name"))
        assertEquals(name, content("<trt:GetProfiles/>", CameraOnvifService.SCHEMA, "Name"))
        val scope = "onvif://www.onvif.org/name/Kitchen%20%26%20caf%C3%A9%20%2F%20tablet"
        assertTrue(response(service, "<tds:GetScopes/>").body.contains(scope))
        assertTrue(CameraOnvifDiscovery("device-id", 8080, name).announcement(listOf("192.168.1.5")).contains(scope))
        assertTrue(response(service, "<tds:GetDeviceInformation/>").body.contains("<tds:SerialNumber>device-id</tds:SerialNumber>"))
    }

    @Test fun announcementsPublishAndWithdrawTheSameCameraIdentity() {
        val discovery = CameraOnvifDiscovery("device-id", 8080)
        val hello = CameraOnvifService.parse(discovery.announcement(listOf("192.168.1.5")).toByteArray())
        val bye = CameraOnvifService.parse(discovery.announcement(emptyList(), bye = true).toByteArray())
        assertEquals(CameraOnvifDiscovery.DISCOVERY + "/Hello",
            hello.getElementsByTagNameNS(CameraOnvifDiscovery.ADDRESSING, "Action").item(0).textContent)
        assertEquals(CameraOnvifDiscovery.DISCOVERY + "/Bye",
            bye.getElementsByTagNameNS(CameraOnvifDiscovery.ADDRESSING, "Action").item(0).textContent)
        assertEquals("urn:uuid:device-id", hello.getElementsByTagNameNS(CameraOnvifDiscovery.ADDRESSING, "Address").item(0).textContent)
        assertEquals("urn:uuid:device-id", bye.getElementsByTagNameNS(CameraOnvifDiscovery.ADDRESSING, "Address").item(0).textContent)
        assertEquals("http://192.168.1.5:8080/onvif/device_service",
            hello.getElementsByTagNameNS(CameraOnvifDiscovery.DISCOVERY, "XAddrs").item(0).textContent)
        assertEquals(0, bye.getElementsByTagNameNS(CameraOnvifDiscovery.DISCOVERY, "XAddrs").length)
        val first = hello.getElementsByTagNameNS(CameraOnvifDiscovery.DISCOVERY, "AppSequence").item(0) as org.w3c.dom.Element
        val last = bye.getElementsByTagNameNS(CameraOnvifDiscovery.DISCOVERY, "AppSequence").item(0) as org.w3c.dom.Element
        assertEquals(first.getAttribute("InstanceId"), last.getAttribute("InstanceId"))
        assertTrue(last.getAttribute("MessageNumber").toLong() > first.getAttribute("MessageNumber").toLong())
        assertTrue(response(service(), "<tds:GetScopes/>").body.contains("onvif://www.onvif.org/Profile/Streaming"))
    }

    private fun event(service: CameraOnvifService, path: String, operation: String, header: String = "") = service.respond(path, """
        <s:Envelope xmlns:s="${CameraOnvifService.SOAP}" xmlns:tev="${CameraOnvifService.EVENTS}"
          xmlns:wsnt="${CameraOnvifService.NOTIFICATION}">
          <s:Header>$header</s:Header><s:Body>$operation</s:Body>
        </s:Envelope>
    """.trimIndent().toByteArray(), "192.168.1.5", 8554)

    private fun subscribe(service: CameraOnvifService, termination: String = "PT60S"): String {
        val created = event(service, "/onvif/event_service",
            "<tev:CreatePullPointSubscription><tev:InitialTerminationTime>$termination</tev:InitialTerminationTime></tev:CreatePullPointSubscription>")
        assertEquals("200 OK", created.status)
        val address = CameraOnvifService.parse(created.body.toByteArray())
            .getElementsByTagNameNS(CameraOnvifService.ADDRESSING, "Address").item(0).textContent
        return java.net.URI(address).path
    }

    private fun pull(service: CameraOnvifService, path: String, timeout: String = "PT0S") = event(service, path,
        "<tev:PullMessages><tev:Timeout>$timeout</tev:Timeout><tev:MessageLimit>10</tev:MessageLimit></tev:PullMessages>")

    @Test fun eventServiceIsListedOnlyWhileMotionEventsAreOn() {
        val s = service()
        assertFalse(response(s, "<tds:GetServices/>").body.contains("event_service"))
        assertEquals("ter:ActionNotSupported: Motion events are off",
            event(s, "/onvif/event_service", "<tev:GetEventProperties/>").fault)
        s.updateEvents(true, false)
        assertTrue(response(s, "<tds:GetServices/>").body.contains("<tds:XAddr>http://192.168.1.5:8554/onvif/event_service</tds:XAddr>"))
        val capabilities = response(s, "<tds:GetCapabilities/>").body
        assertTrue(capabilities.indexOf("<tt:Device>") < capabilities.indexOf("<tt:Events>"))
        assertTrue(capabilities.indexOf("<tt:Events>") < capabilities.indexOf("<tt:Media>"))
        assertTrue(capabilities.contains("<tt:WSPullPointSupport>true</tt:WSPullPointSupport>"))
        val only = response(s, "<tds:GetCapabilities><tds:Category>Events</tds:Category></tds:GetCapabilities>").body
        assertTrue(only.contains("<tt:Events>") && !only.contains("<tt:Device>") && !only.contains("<tt:Media>"))
        val properties = event(s, "/onvif/event_service", "<tev:GetEventProperties/>").body
        CameraOnvifService.parse(properties.toByteArray())
        assertTrue(properties.contains("<tns1:RuleEngine><CellMotionDetector><Motion wstop:topic=\"true\">"))
        assertTrue(properties.contains("<tns1:VideoSource><MotionAlarm wstop:topic=\"true\">"))
        assertTrue(properties.contains("<wsa:Action>${CameraOnvifService.EVENTS}/EventPortType/GetEventPropertiesResponse</wsa:Action>"))
    }

    @Test fun subscriptionsStartWithTheCurrentStateAndGetEveryChange() {
        val s = service()
        s.updateEvents(true, true)
        val path = subscribe(s)
        val first = pull(s, path).body
        CameraOnvifService.parse(first.toByteArray())
        assertTrue(first.contains("tns1:RuleEngine/CellMotionDetector/Motion"))
        assertTrue(first.contains("tns1:VideoSource/MotionAlarm"))
        assertEquals(2, Regex("PropertyOperation=\"Initialized\"").findAll(first).count())
        assertTrue(first.contains("<tt:SimpleItem Name=\"IsMotion\" Value=\"true\"/>"))
        assertTrue(first.contains("<tt:SimpleItem Name=\"State\" Value=\"true\"/>"))
        assertFalse(pull(s, path).body.contains("NotificationMessage"))
        s.updateEvents(true, true)
        assertFalse(pull(s, path).body.contains("NotificationMessage"))
        s.updateEvents(true, false)
        val changed = pull(s, path).body
        assertEquals(2, Regex("PropertyOperation=\"Changed\"").findAll(changed).count())
        assertTrue(changed.contains("<tt:SimpleItem Name=\"IsMotion\" Value=\"false\"/>"))
        assertEquals("200 OK", event(s, path, "<tev:SetSynchronizationPoint/>").status)
        assertEquals(2, Regex("PropertyOperation=\"Initialized\"").findAll(pull(s, path).body).count())
    }

    @Test fun pullMessagesWaitsForMotionWithoutBlockingOtherRequests() {
        val s = service()
        s.updateEvents(true, false)
        val path = subscribe(s)
        pull(s, path)
        var body = ""
        val waiter = Thread { body = pull(s, path, "PT10S").body }
        waiter.start()
        Thread.sleep(200)
        assertTrue(waiter.isAlive)
        assertEquals("200 OK", response(s, "<trt:GetProfiles/>").status)
        s.updateEvents(true, true)
        waiter.join(2000)
        assertFalse(waiter.isAlive)
        assertTrue(body.contains("PropertyOperation=\"Changed\""))
        val closing = Thread { body = pull(s, path, "PT10S").body }
        closing.start()
        Thread.sleep(200)
        s.close()
        closing.join(2000)
        assertFalse(closing.isAlive)
    }

    @Test fun subscriptionsRenewUnsubscribeAndExpire() {
        var now = 1_000_000L
        val s = CameraOnvifService(
            1280, 720, 15, 800_000, false, null, "secret",
            { Base64.getEncoder().encodeToString(it) }, { Base64.getDecoder().decode(it) }, "device-id", "1",
            clock = { now },
        )
        s.updateEvents(true, false)
        val path = subscribe(s, "PT30S")
        val renewed = event(s, path, "<wsnt:Renew><wsnt:TerminationTime>PT2M</wsnt:TerminationTime></wsnt:Renew>").body
        assertTrue(renewed.contains("<wsnt:TerminationTime>${CameraOnvifService.utc(now + 120_000)}</wsnt:TerminationTime>"))
        now += 119_000
        assertEquals("200 OK", pull(s, path).status)
        now += 200_000
        assertEquals("ter:InvalidArgVal: Unknown or expired subscription", pull(s, path).fault)
        val other = subscribe(s)
        assertEquals("200 OK", event(s, other, "<wsnt:Unsubscribe/>").status)
        assertNotNull(pull(s, other).fault)
        val kept = subscribe(s)
        s.updateEvents(false, false)
        s.updateEvents(true, false)
        assertNotNull(pull(s, kept).fault)
        assertEquals(60_000L, CameraOnvifService.duration("PT1M"))
        assertEquals(90_500L, CameraOnvifService.duration("PT1M30.5S"))
        assertEquals(86_400_000L, CameraOnvifService.duration("P1D"))
        assertNull(CameraOnvifService.duration("PT"))
        assertEquals(0L, CameraOnvifService.instant("1970-01-01T00:00:00Z"))
    }

    @Test fun eventRequestsNeedAuthentication() {
        val s = service(auth = true)
        s.updateEvents(true, false)
        assertEquals("400 Bad Request", event(s, "/onvif/event_service", "<tev:GetEventProperties/>").status)
        assertEquals("200 OK", event(s, "/onvif/event_service", "<tev:GetEventProperties/>", token()).status)
        assertEquals("404 Not Found", event(s, "/onvif/subscription/x", "<tev:PullMessages/>").status)
    }

    private fun streamRequest(profile: String = "camera") = "<trt:GetStreamUri><trt:StreamSetup><tt:Stream>RTP-Unicast</tt:Stream>" +
        "<tt:Transport><tt:Protocol>RTSP</tt:Protocol></tt:Transport></trt:StreamSetup><trt:ProfileToken>$profile</trt:ProfileToken></trt:GetStreamUri>"

    private fun token(password: String = "secret", time: Long = System.currentTimeMillis()): String {
        val nonce = java.util.UUID.randomUUID().toString().toByteArray()
        val created = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").apply { timeZone = TimeZone.getTimeZone("UTC") }.format(Date(time))
        val digest = Base64.getEncoder().encodeToString(MessageDigest.getInstance("SHA-1").digest(nonce + created.toByteArray() + password.toByteArray()))
        return "<wsse:Security xmlns:wsse=\"${CameraOnvifService.SECURITY}\" xmlns:wsu=\"${CameraOnvifService.UTILITY}\"><wsse:UsernameToken>" +
            "<wsse:Username>viewer</wsse:Username><wsse:Password Type=\"${CameraOnvifService.SECURITY}#PasswordDigest\">$digest</wsse:Password>" +
            "<wsse:Nonce>${Base64.getEncoder().encodeToString(nonce)}</wsse:Nonce><wsu:Created>$created</wsu:Created></wsse:UsernameToken></wsse:Security>"
    }
}
