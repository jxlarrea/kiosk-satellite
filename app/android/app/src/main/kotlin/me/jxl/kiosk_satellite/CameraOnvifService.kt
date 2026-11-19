package me.jxl.kiosk_satellite

import java.io.ByteArrayInputStream
import java.net.InetAddress
import java.net.NetworkInterface
import java.security.MessageDigest
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone
import javax.xml.parsers.DocumentBuilderFactory
import org.w3c.dom.Element

/**
 * Read-only ONVIF device and Media1 services for the shared camera stream,
 * plus an event service that reports motion over PullPoint subscriptions
 * while motion events are on (issue #1098).
 */
class CameraOnvifService(
    private var width: Int,
    private var height: Int,
    private var fps: Int,
    private var bitrate: Int,
    private val audio: Boolean,
    private val username: String?,
    private val password: String,
    private val encodeBase64: (ByteArray) -> String,
    private val decodeBase64: (String) -> ByteArray,
    private val deviceId: String,
    private val firmware: String,
    private val networkInfo: (String) -> NetworkInfo? = ::networkInfoFor,
    deviceName: String = "Kiosk Satellite",
    private val tls: Boolean = false,
    private var h264Profile: String = "Baseline",
    private val onH264Profile: (String) -> Unit = {},
    private val clock: () -> Long = System::currentTimeMillis,
) {
    data class Response(val status: String, val body: String, val operation: String = "", val fault: String? = null)
    data class NetworkInfo(val name: String, val enabled: Boolean, val hardwareAddress: String?, val mtu: Int?)
    private val name = deviceName.trim().ifEmpty { "Kiosk Satellite" }
    private val scopes = scopes(name)
    private val usedTokens = mutableMapOf<String, Long>()

    // Event state has a lock of its own: a PullMessages waits on it for up
    // to a minute and must not hold up the device and media requests.
    private class Subscription(var expires: Long) { val messages = ArrayDeque<String>() }
    private val events = Object()
    private val subscriptions = mutableMapOf<Int, Subscription>()
    private var nextSubscription = 1
    @Volatile private var eventsEnabled = false
    private var motion = false
    private var closed = false

    /** Turn the event service on or off, and tell every subscription when motion changes. */
    fun updateEvents(enabled: Boolean, motion: Boolean) = synchronized(events) {
        val changed = motion != this.motion
        this.motion = motion
        eventsEnabled = enabled
        if (!enabled) subscriptions.clear()
        else if (changed) subscriptions.values.forEach { queue(it, "Changed") }
        events.notifyAll()
    }

    /** Release any PullMessages still waiting when the server goes away. */
    fun close() = synchronized(events) {
        closed = true
        subscriptions.clear()
        events.notifyAll()
    }

    @Synchronized fun updateVideo(width: Int, height: Int, fps: Int, bitrate: Int) {
        this.width = width
        this.height = height
        this.fps = fps
        this.bitrate = bitrate
    }

    /** Encoders pick their own profile, so report the one in the stream's SPS. */
    @Synchronized fun updateParameterSet(sps: ByteArray) {
        val profile = h264ProfileOf(sps) ?: return
        if (profile == h264Profile) return
        h264Profile = profile
        onH264Profile(profile)
    }

    fun respond(path: String, bytes: ByteArray, host: String, port: Int): Response {
        val subscription = SUBSCRIPTION_PATH.matchEntire(path)?.groupValues?.get(1)?.toIntOrNull()
        val namespaces = when {
            path == "/onvif/device_service" -> listOf(DEVICE)
            path == "/onvif/media_service" -> listOf(MEDIA)
            path == "/onvif/event_service" || subscription != null -> listOf(EVENTS, NOTIFICATION)
            else -> return Response("404 Not Found", "")
        }
        val document = try { parse(bytes) } catch (_: Exception) {
            return fault("ter:InvalidArgVal", "Invalid SOAP request", "400 Bad Request")
        }
        val envelope = document.documentElement
        val body = envelope.child(SOAP, "Body")
        val operation = body?.let { node ->
            (0 until node.childNodes.length).map { node.childNodes.item(it) }.filterIsInstance<Element>().singleOrNull()
        } ?: return fault("ter:InvalidArgVal", "Expected one SOAP operation", "400 Bad Request")
        if (envelope.namespaceURI != SOAP || envelope.localName != "Envelope" || operation.namespaceURI !in namespaces) {
            return fault("ter:ActionNotSupported", "Unsupported service")
        }
        val name = operation.localName
        val response = if (namespaces.first() == EVENTS) answerEvents(name, envelope, operation, subscription, host, port)
            else synchronized(this) { answer(name, namespaces.first(), envelope, operation, host, port) }
        return response.copy(operation = name)
    }

    private fun answer(name: String, namespace: String, envelope: Element, operation: Element, host: String, port: Int): Response {
        // ONVIF clients obtain UTC before constructing their UsernameToken.
        if (name != "GetSystemDateAndTime" && !authenticated(envelope)) {
            return fault("ter:NotAuthorized", "Authentication required", "400 Bad Request")
        }
        val base = "${if (tls) "https" else "http"}://${xml(host)}:$port/onvif"
        val profileToken = operation.child(MEDIA, "ProfileToken")?.textContent
        if (name in listOf("GetProfile", "GetStreamUri", "GetSnapshotUri") && profileToken != "camera") {
            return fault("ter:InvalidArgVal", "Unknown profile token", subcode = "ter:NoProfile")
        }
        val content = if (namespace == DEVICE) when (name) {
            "GetDeviceInformation" -> "<tds:Manufacturer>Kiosk Satellite</tds:Manufacturer>" +
                "<tds:Model>${xml(this.name)}</tds:Model><tds:FirmwareVersion>${xml(firmware)}</tds:FirmwareVersion>" +
                "<tds:SerialNumber>${xml(deviceId)}</tds:SerialNumber><tds:HardwareId>camera</tds:HardwareId>"
            "GetNetworkInterfaces" -> {
                val network = networkInfo(host) ?: return fault("ter:ActionNotSupported",
                    "GetNetworkInterfaces is not implemented for this interface")
                // Android can hide the physical MAC. Leave that field empty so
                // clients can use the persistent serial number as the identity.
                "<tds:NetworkInterfaces token=\"${xml(network.name)}\"><tt:Enabled>${network.enabled}</tt:Enabled>" +
                    "<tt:Info><tt:Name>${xml(network.name)}</tt:Name>" +
                    "<tt:HwAddress>${xml(network.hardwareAddress ?: "")}</tt:HwAddress>" +
                    (network.mtu?.let { "<tt:MTU>$it</tt:MTU>" } ?: "") +
                    "</tt:Info></tds:NetworkInterfaces>"
            }
            "GetSystemDateAndTime" -> dateAndTime()
            "GetServices" -> service("tds", DEVICE, "$base/device_service", operation) +
                service("trt", MEDIA, "$base/media_service", operation) +
                (if (eventsEnabled) service("tev", EVENTS, "$base/event_service", operation) else "")
            "GetCapabilities" -> {
                val category = operation.child(DEVICE, "Category")?.textContent ?: "All"
                if (category !in listOf("All", "Device", "Media") && !(category == "Events" && eventsEnabled)) {
                    return fault("ter:ActionNotSupported", "Unsupported capability")
                }
                "<tds:Capabilities>" + (if (category in listOf("All", "Device"))
                    "<tt:Device><tt:XAddr>$base/device_service</tt:XAddr>" +
                    "<tt:Network><tt:IPFilter>false</tt:IPFilter><tt:ZeroConfiguration>false</tt:ZeroConfiguration>" +
                    "<tt:IPVersion6>false</tt:IPVersion6><tt:DynDNS>false</tt:DynDNS></tt:Network>" +
                    "<tt:System><tt:DiscoveryResolve>false</tt:DiscoveryResolve><tt:DiscoveryBye>true</tt:DiscoveryBye>" +
                    "<tt:RemoteDiscovery>false</tt:RemoteDiscovery><tt:SystemBackup>false</tt:SystemBackup>" +
                    "<tt:SystemLogging>false</tt:SystemLogging><tt:FirmwareUpgrade>false</tt:FirmwareUpgrade>" +
                    "<tt:SupportedVersions><tt:Major>2</tt:Major><tt:Minor>0</tt:Minor></tt:SupportedVersions></tt:System>" +
                    "<tt:Security><tt:TLS1.1>false</tt:TLS1.1><tt:TLS1.2>$tls</tt:TLS1.2>" +
                    "<tt:OnboardKeyGeneration>false</tt:OnboardKeyGeneration><tt:AccessPolicyConfig>false</tt:AccessPolicyConfig>" +
                    "<tt:X.509Token>false</tt:X.509Token><tt:SAMLToken>false</tt:SAMLToken>" +
                    "<tt:KerberosToken>false</tt:KerberosToken><tt:RELToken>false</tt:RELToken></tt:Security></tt:Device>" else "") +
                    (if (category in listOf("All", "Events") && eventsEnabled) "<tt:Events><tt:XAddr>$base/event_service</tt:XAddr>" +
                        "<tt:WSSubscriptionPolicySupport>false</tt:WSSubscriptionPolicySupport>" +
                        "<tt:WSPullPointSupport>true</tt:WSPullPointSupport>" +
                        "<tt:WSPausableSubscriptionManagerInterfaceSupport>false</tt:WSPausableSubscriptionManagerInterfaceSupport>" +
                        "</tt:Events>" else "") +
                    (if (category in listOf("All", "Media")) "<tt:Media><tt:XAddr>$base/media_service</tt:XAddr>" +
                        "<tt:StreamingCapabilities><tt:RTPMulticast>false</tt:RTPMulticast>" +
                        "<tt:RTP_TCP>false</tt:RTP_TCP><tt:RTP_RTSP_TCP>true</tt:RTP_RTSP_TCP>" +
                        "</tt:StreamingCapabilities></tt:Media>" else "") + "</tds:Capabilities>"
            }
            "GetServiceCapabilities" -> deviceCapabilities()
            "GetScopes" -> scopes.split(' ').joinToString("") {
                "<tds:Scopes><tt:ScopeDef>Fixed</tt:ScopeDef><tt:ScopeItem>$it</tt:ScopeItem></tds:Scopes>"
            }
            "GetHostname" -> "<tds:HostnameInformation><tt:FromDHCP>false</tt:FromDHCP>" +
                "<tt:Name>${xml(this.name)}</tt:Name></tds:HostnameInformation>"
            else -> return fault("ter:ActionNotSupported", "Unsupported device operation: ${xml(name)}")
        } else when (name) {
            "GetServiceCapabilities" -> mediaCapabilities()
            "GetProfiles" -> profile("Profiles")
            "GetProfile" -> profile("Profile")
            "GetStreamUri" -> {
                val setup = operation.child(MEDIA, "StreamSetup")
                val transport = setup?.child(SCHEMA, "Transport")?.child(SCHEMA, "Protocol")?.textContent
                if (setup?.child(SCHEMA, "Stream")?.textContent != "RTP-Unicast" || transport != "RTSP") {
                    return fault("ter:InvalidArgVal", "Use RTP-Unicast with RTSP transport", subcode = "ter:InvalidStreamSetup")
                }
                "<trt:MediaUri><tt:Uri>${if (tls) "rtsps" else "rtsp"}://${xml(host)}:$port/camera</tt:Uri>" +
                    "<tt:InvalidAfterConnect>false</tt:InvalidAfterConnect><tt:InvalidAfterReboot>false</tt:InvalidAfterReboot>" +
                    "<tt:Timeout>PT0S</tt:Timeout></trt:MediaUri>"
            }
            // A JPEG of the current frame, for clients like UniFi Protect
            // that take event thumbnails from stills (issue #1506).
            "GetSnapshotUri" -> "<trt:MediaUri><tt:Uri>${if (tls) "https" else "http"}://${xml(host)}:$port$SNAPSHOT_PATH</tt:Uri>" +
                "<tt:InvalidAfterConnect>false</tt:InvalidAfterConnect><tt:InvalidAfterReboot>false</tt:InvalidAfterReboot>" +
                "<tt:Timeout>PT0S</tt:Timeout></trt:MediaUri>"
            "GetVideoSources" -> "<trt:VideoSources token=\"camera\"><tt:Framerate>$fps</tt:Framerate>" +
                "<tt:Resolution><tt:Width>$width</tt:Width><tt:Height>$height</tt:Height></tt:Resolution></trt:VideoSources>"
            "GetVideoSourceConfigurations", "GetCompatibleVideoSourceConfigurations" -> videoSource("trt:Configurations")
            "GetVideoEncoderConfigurations", "GetCompatibleVideoEncoderConfigurations" -> videoEncoder("trt:Configurations")
            "GetVideoSourceConfiguration" -> {
                if (operation.child(MEDIA, "ConfigurationToken")?.textContent != "video_source") return noConfiguration()
                videoSource("trt:Configuration")
            }
            "GetVideoEncoderConfiguration" -> {
                if (operation.child(MEDIA, "ConfigurationToken")?.textContent != "video_encoder") return noConfiguration()
                videoEncoder("trt:Configuration")
            }
            "GetVideoEncoderConfigurationOptions" -> {
                if (operation.child(MEDIA, "ConfigurationToken")?.textContent.let { it != null && it != "video_encoder" }) return noConfiguration()
                if (operation.child(MEDIA, "ProfileToken")?.textContent.let { it != null && it != "camera" }) {
                    return fault("ter:InvalidArgVal", "Unknown profile token", subcode = "ter:NoProfile")
                }
                videoEncoderOptions()
            }
            "GetAudioSources" -> if (audio) "<trt:AudioSources token=\"microphone\"><tt:Channels>1</tt:Channels></trt:AudioSources>" else ""
            "GetAudioSourceConfigurations", "GetCompatibleAudioSourceConfigurations" -> if (audio) audioSource("trt:Configurations") else ""
            "GetAudioEncoderConfigurations", "GetCompatibleAudioEncoderConfigurations" -> if (audio) audioEncoder("trt:Configurations") else ""
            "GetAudioSourceConfiguration" -> {
                if (!audio || operation.child(MEDIA, "ConfigurationToken")?.textContent != "audio_source") return noConfiguration()
                audioSource("trt:Configuration")
            }
            "GetAudioEncoderConfiguration" -> {
                if (!audio || operation.child(MEDIA, "ConfigurationToken")?.textContent != "audio_encoder") return noConfiguration()
                audioEncoder("trt:Configuration")
            }
            else -> return fault("ter:ActionNotSupported", "Unsupported media operation: ${xml(name)}")
        }
        val prefix = if (namespace == DEVICE) "tds" else "trt"
        return Response("200 OK", envelope("<$prefix:${name}Response>$content</$prefix:${name}Response>"))
    }

    /**
     * The event service and its subscriptions. Motion is a property: each
     * subscription starts with its current value (Initialized) and then
     * gets every change, on two topics because NVRs listen for either.
     */
    private fun answerEvents(name: String, envelope: Element, operation: Element, id: Int?, host: String, port: Int): Response {
        if (!authenticated(envelope)) return fault("ter:NotAuthorized", "Authentication required", "400 Bad Request")
        if (!eventsEnabled) return fault("ter:ActionNotSupported", "Motion events are off")
        val now = clock()
        if (id == null) {
            val content = when (name) {
                "GetServiceCapabilities" -> eventCapabilities()
                "GetEventProperties" -> eventProperties()
                "CreatePullPointSubscription" -> synchronized(events) {
                    expire(now)
                    // A client that reconnects without unsubscribing must not
                    // lock the others out, so the one closest to expiring goes.
                    if (subscriptions.size >= MAX_SUBSCRIPTIONS) {
                        subscriptions.remove(subscriptions.minByOrNull { it.value.expires }!!.key)
                    }
                    val number = nextSubscription++
                    val subscription = Subscription(terminationTime(operation.child(EVENTS, "InitialTerminationTime")?.textContent, now))
                    queue(subscription, "Initialized")
                    subscriptions[number] = subscription
                    "<tev:SubscriptionReference><wsa:Address>${if (tls) "https" else "http"}://${xml(host)}:$port/onvif/subscription/$number" +
                        "</wsa:Address></tev:SubscriptionReference><wsnt:CurrentTime>${utc(now)}</wsnt:CurrentTime>" +
                        "<wsnt:TerminationTime>${utc(subscription.expires)}</wsnt:TerminationTime>"
                }
                else -> return fault("ter:ActionNotSupported", "Unsupported event operation: ${xml(name)}")
            }
            return eventResponse(name, "$EVENTS/EventPortType", "tev", content)
        }
        return when (name) {
            "PullMessages" -> {
                val wait = operation.child(EVENTS, "Timeout")?.textContent?.let(::duration)?.coerceIn(0, MAX_PULL_WAIT) ?: MAX_PULL_WAIT
                val limit = operation.child(EVENTS, "MessageLimit")?.textContent?.trim()?.toIntOrNull()?.coerceIn(1, MAX_QUEUED) ?: MAX_QUEUED
                val (messages, expires) = synchronized(events) {
                    expire(now)
                    val subscription = subscriptions[id] ?: return unknownSubscription()
                    // A client that keeps pulling keeps its subscription, renewed or not.
                    subscription.expires = maxOf(subscription.expires, now + wait + 60_000)
                    val deadline = now + wait
                    while (subscription.messages.isEmpty() && !closed && subscriptions[id] === subscription) {
                        val left = deadline - clock()
                        if (left <= 0) break
                        events.wait(left)
                    }
                    if (subscriptions[id] !== subscription) return unknownSubscription()
                    List(minOf(limit, subscription.messages.size)) { subscription.messages.removeFirst() } to subscription.expires
                }
                eventResponse(name, "$EVENTS/PullPointSubscription", "tev",
                    "<tev:CurrentTime>${utc(clock())}</tev:CurrentTime><tev:TerminationTime>${utc(expires)}</tev:TerminationTime>" +
                        messages.joinToString(""))
            }
            "SetSynchronizationPoint" -> synchronized(events) {
                expire(now)
                queue(subscriptions[id] ?: return unknownSubscription(), "Initialized")
                events.notifyAll()
                eventResponse(name, "$EVENTS/PullPointSubscription", "tev", "")
            }
            "Renew" -> synchronized(events) {
                expire(now)
                val subscription = subscriptions[id] ?: return unknownSubscription()
                subscription.expires = terminationTime(operation.child(NOTIFICATION, "TerminationTime")?.textContent, now)
                eventResponse(name, SUBSCRIPTION_MANAGER, "wsnt",
                    "<wsnt:TerminationTime>${utc(subscription.expires)}</wsnt:TerminationTime><wsnt:CurrentTime>${utc(now)}</wsnt:CurrentTime>")
            }
            "Unsubscribe" -> synchronized(events) {
                subscriptions.remove(id) ?: return unknownSubscription()
                events.notifyAll()
                eventResponse(name, SUBSCRIPTION_MANAGER, "wsnt", "")
            }
            else -> fault("ter:ActionNotSupported", "Unsupported subscription operation: ${xml(name)}")
        }
    }

    private fun eventResponse(name: String, actionBase: String, prefix: String, content: String) =
        Response("200 OK", envelope("<$prefix:${name}Response>$content</$prefix:${name}Response>", "$actionBase/${name}Response"))

    private fun unknownSubscription() = fault("ter:InvalidArgVal", "Unknown or expired subscription")

    private fun expire(now: Long) {
        subscriptions.entries.removeAll { it.value.expires < now }
    }

    private fun queue(subscription: Subscription, operation: String) {
        val time = utc(clock())
        subscription.messages.addLast(notification("tns1:RuleEngine/CellMotionDetector/Motion", time, operation,
            "<tt:SimpleItem Name=\"VideoSourceConfigurationToken\" Value=\"video_source\"/>" +
                "<tt:SimpleItem Name=\"VideoAnalyticsConfigurationToken\" Value=\"analytics\"/>" +
                "<tt:SimpleItem Name=\"Rule\" Value=\"MotionDetectorRule\"/>", "IsMotion"))
        subscription.messages.addLast(notification("tns1:VideoSource/MotionAlarm", time, operation,
            "<tt:SimpleItem Name=\"Source\" Value=\"camera\"/>", "State"))
        while (subscription.messages.size > MAX_QUEUED) subscription.messages.removeFirst()
    }

    private fun notification(topic: String, time: String, operation: String, source: String, item: String) =
        "<wsnt:NotificationMessage><wsnt:Topic Dialect=\"$CONCRETE_SET\">$topic</wsnt:Topic><wsnt:Message>" +
            "<tt:Message UtcTime=\"$time\" PropertyOperation=\"$operation\"><tt:Source>$source</tt:Source>" +
            "<tt:Data><tt:SimpleItem Name=\"$item\" Value=\"$motion\"/></tt:Data></tt:Message></wsnt:Message></wsnt:NotificationMessage>"

    private fun eventCapabilities() = "<tev:Capabilities WSSubscriptionPolicySupport=\"false\" WSPullPointSupport=\"true\" " +
        "WSPausableSubscriptionManagerInterfaceSupport=\"false\" MaxNotificationProducers=\"0\" " +
        "MaxPullPoints=\"$MAX_SUBSCRIPTIONS\" PersistentNotificationStorage=\"false\"/>"

    private fun eventProperties(): String {
        fun description(source: List<Pair<String, String>>, data: String) = "<tt:MessageDescription IsProperty=\"true\"><tt:Source>" +
            source.joinToString("") { (item, type) -> "<tt:SimpleItemDescription Name=\"$item\" Type=\"$type\"/>" } +
            "</tt:Source><tt:Data><tt:SimpleItemDescription Name=\"$data\" Type=\"xs:boolean\"/></tt:Data></tt:MessageDescription>"
        return "<tev:TopicNamespaceLocation>http://www.onvif.org/onvif/ver10/topics/topicns.xml</tev:TopicNamespaceLocation>" +
            "<wsnt:FixedTopicSet>true</wsnt:FixedTopicSet><wstop:TopicSet>" +
            "<tns1:RuleEngine><CellMotionDetector><Motion wstop:topic=\"true\">" +
            description(listOf("VideoSourceConfigurationToken" to "tt:ReferenceToken",
                "VideoAnalyticsConfigurationToken" to "tt:ReferenceToken", "Rule" to "xs:string"), "IsMotion") +
            "</Motion></CellMotionDetector></tns1:RuleEngine>" +
            "<tns1:VideoSource><MotionAlarm wstop:topic=\"true\">" +
            description(listOf("Source" to "tt:ReferenceToken"), "State") +
            "</MotionAlarm></tns1:VideoSource></wstop:TopicSet>" +
            "<wsnt:TopicExpressionDialect>$CONCRETE_SET</wsnt:TopicExpressionDialect>" +
            "<wsnt:TopicExpressionDialect>http://docs.oasis-open.org/wsnt/t-1/TopicExpression/ConcreteSet</wsnt:TopicExpressionDialect>" +
            "<tev:MessageContentFilterDialect>http://www.onvif.org/ver10/tev/messageContentFilter/ItemFilter</tev:MessageContentFilterDialect>" +
            "<tev:MessageContentSchemaLocation>http://www.onvif.org/onvif/ver10/schema/onvif.xsd</tev:MessageContentSchemaLocation>"
    }

    /** A termination time sent as a duration from now or as a time, held between 10 seconds and a day away. */
    private fun terminationTime(text: String?, now: Long): Long {
        val value = text?.trim().orEmpty()
        val at = duration(value)?.let { now + it } ?: instant(value) ?: (now + 60_000)
        return at.coerceIn(now + 10_000, now + 86_400_000)
    }

    private fun authenticated(envelope: Element): Boolean {
        if (username == null) return true
        val token = envelope.child(SOAP, "Header")?.child(SECURITY, "Security")?.child(SECURITY, "UsernameToken") ?: return false
        if (token.child(SECURITY, "Username")?.textContent != username) return false
        val supplied = token.child(SECURITY, "Password") ?: return false
        if (!supplied.getAttribute("Type").endsWith("#PasswordDigest")) return false
        val nonce = token.child(SECURITY, "Nonce")?.textContent ?: return false
        val created = token.child(UTILITY, "Created")?.textContent ?: return false
        val timestamp = listOf("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", "yyyy-MM-dd'T'HH:mm:ss'Z'").firstNotNullOfOrNull { pattern ->
            try {
                val format = SimpleDateFormat(pattern, Locale.US).apply { timeZone = TimeZone.getTimeZone("UTC"); isLenient = false }
                val position = java.text.ParsePosition(0)
                format.parse(created, position)?.takeIf { position.index == created.length }?.time
            } catch (_: Exception) { null }
        } ?: return false
        val now = System.currentTimeMillis()
        if (kotlin.math.abs(now - timestamp) > 300_000) return false
        val expected = try {
            encodeBase64(MessageDigest.getInstance("SHA-1").digest(decodeBase64(nonce) + created.toByteArray() + password.toByteArray()))
        } catch (_: Exception) { return false }
        if (!MessageDigest.isEqual(expected.toByteArray(), supplied.textContent.toByteArray())) return false
        synchronized(usedTokens) {
            usedTokens.entries.removeAll { it.value < now - 300_000 }
            val key = expected
            if (usedTokens.containsKey(key) || usedTokens.size >= 2048) return false
            usedTokens[key] = timestamp
        }
        return true
    }

    private fun profile(tag: String) = "<trt:$tag token=\"camera\" fixed=\"true\"><tt:Name>${xml(name)}</tt:Name>" +
        videoSource("tt:VideoSourceConfiguration") + (if (audio) audioSource("tt:AudioSourceConfiguration") else "") +
        videoEncoder("tt:VideoEncoderConfiguration") + (if (audio) audioEncoder("tt:AudioEncoderConfiguration") else "") + "</trt:$tag>"

    private fun videoSource(tag: String) = "<$tag token=\"video_source\"><tt:Name>${xml(name)}</tt:Name><tt:UseCount>1</tt:UseCount>" +
        "<tt:SourceToken>camera</tt:SourceToken><tt:Bounds x=\"0\" y=\"0\" width=\"$width\" height=\"$height\"/></$tag>"

    private fun videoEncoder(tag: String) = "<$tag token=\"video_encoder\"><tt:Name>H.264</tt:Name><tt:UseCount>1</tt:UseCount>" +
        "<tt:Encoding>H264</tt:Encoding><tt:Resolution><tt:Width>$width</tt:Width><tt:Height>$height</tt:Height></tt:Resolution>" +
        "<tt:Quality>5</tt:Quality><tt:RateControl><tt:FrameRateLimit>$fps</tt:FrameRateLimit>" +
        "<tt:EncodingInterval>1</tt:EncodingInterval><tt:BitrateLimit>${bitrate / 1000}</tt:BitrateLimit></tt:RateControl>" +
        "<tt:H264><tt:GovLength>$fps</tt:GovLength><tt:H264Profile>$h264Profile</tt:H264Profile></tt:H264>" +
        multicast() + "<tt:SessionTimeout>PT60S</tt:SessionTimeout></$tag>"

    // The stream is set up in Kiosk Satellite, so the only options are the current settings.
    private fun videoEncoderOptions() = "<trt:Options><tt:QualityRange><tt:Min>5</tt:Min><tt:Max>5</tt:Max></tt:QualityRange>" +
        "<tt:H264><tt:ResolutionsAvailable><tt:Width>$width</tt:Width><tt:Height>$height</tt:Height></tt:ResolutionsAvailable>" +
        "<tt:GovLengthRange><tt:Min>$fps</tt:Min><tt:Max>$fps</tt:Max></tt:GovLengthRange>" +
        "<tt:FrameRateRange><tt:Min>$fps</tt:Min><tt:Max>$fps</tt:Max></tt:FrameRateRange>" +
        "<tt:EncodingIntervalRange><tt:Min>1</tt:Min><tt:Max>1</tt:Max></tt:EncodingIntervalRange>" +
        "<tt:H264ProfilesSupported>$h264Profile</tt:H264ProfilesSupported></tt:H264></trt:Options>"

    private fun audioSource(tag: String) = "<$tag token=\"audio_source\"><tt:Name>Microphone</tt:Name><tt:UseCount>1</tt:UseCount>" +
        "<tt:SourceToken>microphone</tt:SourceToken></$tag>"

    private fun audioEncoder(tag: String) = "<$tag token=\"audio_encoder\"><tt:Name>AAC</tt:Name><tt:UseCount>1</tt:UseCount>" +
        "<tt:Encoding>AAC</tt:Encoding><tt:Bitrate>32</tt:Bitrate><tt:SampleRate>16</tt:SampleRate>" +
        multicast() + "<tt:SessionTimeout>PT60S</tt:SessionTimeout></$tag>"

    private fun multicast() = "<tt:Multicast><tt:Address><tt:Type>IPv4</tt:Type><tt:IPv4Address>0.0.0.0</tt:IPv4Address>" +
        "</tt:Address><tt:Port>0</tt:Port><tt:TTL>1</tt:TTL><tt:AutoStart>false</tt:AutoStart></tt:Multicast>"

    private fun service(prefix: String, namespace: String, address: String, request: Element): String =
        "<tds:Service><tds:Namespace>$namespace</tds:Namespace><tds:XAddr>$address</tds:XAddr>" +
            (if (request.child(DEVICE, "IncludeCapability")?.textContent in listOf("true", "1"))
                "<tds:Capabilities>${when (prefix) {
                    "tds" -> deviceCapabilities()
                    "trt" -> mediaCapabilities()
                    else -> eventCapabilities()
                }}</tds:Capabilities>" else "") +
            "<tds:Version><tt:Major>2</tt:Major><tt:Minor>0</tt:Minor></tds:Version></tds:Service>"

    private fun deviceCapabilities() = "<tds:Capabilities><tds:Network IPFilter=\"false\" ZeroConfiguration=\"false\" IPVersion6=\"false\" DynDNS=\"false\"/>" +
        "<tds:Security TLS1.2=\"$tls\" UsernameToken=\"true\" HttpDigest=\"false\"/><tds:System DiscoveryResolve=\"false\" DiscoveryBye=\"true\" RemoteDiscovery=\"false\"/>" +
        "</tds:Capabilities>"

    private fun mediaCapabilities() = "<trt:Capabilities SnapshotUri=\"true\"><trt:ProfileCapabilities MaximumNumberOfProfiles=\"1\"/>" +
        "<trt:StreamingCapabilities RTPMulticast=\"false\" RTP_TCP=\"false\" RTP_RTSP_TCP=\"true\"/></trt:Capabilities>"

    private fun dateAndTime(): String {
        val utc = Calendar.getInstance(TimeZone.getTimeZone("UTC"))
        return "<tds:SystemDateAndTime><tt:DateTimeType>Manual</tt:DateTimeType><tt:DaylightSavings>false</tt:DaylightSavings>" +
            "<tt:TimeZone><tt:TZ>UTC0</tt:TZ></tt:TimeZone><tt:UTCDateTime><tt:Time>" +
            "<tt:Hour>${utc.get(Calendar.HOUR_OF_DAY)}</tt:Hour><tt:Minute>${utc.get(Calendar.MINUTE)}</tt:Minute>" +
            "<tt:Second>${utc.get(Calendar.SECOND)}</tt:Second></tt:Time><tt:Date><tt:Year>${utc.get(Calendar.YEAR)}</tt:Year>" +
            "<tt:Month>${utc.get(Calendar.MONTH) + 1}</tt:Month><tt:Day>${utc.get(Calendar.DAY_OF_MONTH)}</tt:Day>" +
            "</tt:Date></tt:UTCDateTime></tds:SystemDateAndTime>"
    }

    private fun noConfiguration() = fault("ter:InvalidArgVal", "Unknown configuration token", subcode = "ter:NoConfig")
    private fun fault(code: String, reason: String, status: String = "500 Internal Server Error", subcode: String? = null) =
        Response(status, envelope("<s:Fault><s:Code><s:Value>s:Sender</s:Value><s:Subcode><s:Value>$code</s:Value>" +
            (if (subcode != null) "<s:Subcode><s:Value>$subcode</s:Value></s:Subcode>" else "") +
            "</s:Subcode></s:Code><s:Reason><s:Text xml:lang=\"en\">$reason</s:Text></s:Reason></s:Fault>"),
            fault = "${subcode ?: code}: $reason")

    companion object {
        const val SOAP = "http://www.w3.org/2003/05/soap-envelope"
        const val DEVICE = "http://www.onvif.org/ver10/device/wsdl"
        const val MEDIA = "http://www.onvif.org/ver10/media/wsdl"
        const val SCHEMA = "http://www.onvif.org/ver10/schema"
        const val SECURITY = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
        const val UTILITY = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
        const val SCOPES = "onvif://www.onvif.org/Profile/Streaming onvif://www.onvif.org/type/video_encoder"
        const val EVENTS = "http://www.onvif.org/ver10/events/wsdl"
        const val NOTIFICATION = "http://docs.oasis-open.org/wsn/b-2"
        const val ADDRESSING = "http://www.w3.org/2005/08/addressing"
        const val TOPICS = "http://docs.oasis-open.org/wsn/t-1"
        const val CONCRETE_SET = "http://www.onvif.org/ver10/tev/topicExpression/ConcreteSet"
        private const val SUBSCRIPTION_MANAGER = "http://docs.oasis-open.org/wsn/bw-2/SubscriptionManager"
        const val SNAPSHOT_PATH = "/onvif/snapshot"
        private val SUBSCRIPTION_PATH = Regex("/onvif/subscription/([0-9]{1,9})")
        private const val MAX_SUBSCRIPTIONS = 8
        private const val MAX_QUEUED = 100
        private const val MAX_PULL_WAIT = 60_000L

        /** An xs:duration such as PT60S or PT1M30S, in milliseconds. */
        fun duration(text: String): Long? {
            val match = Regex("P(?:([0-9]+)D)?(?:T(?:([0-9]+)H)?(?:([0-9]+)M)?(?:([0-9]+(?:\\.[0-9]+)?)S)?)?")
                .matchEntire(text.trim()) ?: return null
            if (match.groupValues.drop(1).all { it.isEmpty() }) return null
            val (days, hours, minutes, seconds) = match.destructured
            return ((days.toLongOrNull() ?: 0) * 86_400_000 + (hours.toLongOrNull() ?: 0) * 3_600_000 +
                (minutes.toLongOrNull() ?: 0) * 60_000 + ((seconds.toDoubleOrNull() ?: 0.0) * 1000).toLong())
        }

        /** An xs:dateTime, in UTC milliseconds. */
        fun instant(text: String): Long? = listOf("yyyy-MM-dd'T'HH:mm:ss.SSSXXX", "yyyy-MM-dd'T'HH:mm:ssXXX").firstNotNullOfOrNull { pattern ->
            try {
                val format = SimpleDateFormat(pattern, Locale.US).apply { timeZone = TimeZone.getTimeZone("UTC"); isLenient = false }
                val position = java.text.ParsePosition(0)
                format.parse(text, position)?.takeIf { position.index == text.length }?.time
            } catch (_: Exception) { null }
        }

        fun utc(millis: Long): String = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
            .apply { timeZone = TimeZone.getTimeZone("UTC") }.format(java.util.Date(millis))

        fun scopes(deviceName: String): String = SCOPES + " onvif://www.onvif.org/name/" +
            java.net.URLEncoder.encode(deviceName.trim().ifEmpty { "Kiosk Satellite" }, "UTF-8").replace("+", "%20")

        private fun networkInfoFor(host: String): NetworkInfo? = try {
            NetworkInterface.getByInetAddress(InetAddress.getByName(host))?.let { network ->
                val mac = try { readableMac(network.hardwareAddress) } catch (_: Exception) { null }
                val mtu = try { network.mtu.takeIf { it > 0 } } catch (_: Exception) { null }
                NetworkInfo(network.name, network.isUp, mac, mtu)
            }
        } catch (_: Exception) { null }

        internal fun readableMac(bytes: ByteArray?): String? {
            if (bytes == null || bytes.size != 6 || bytes[0].toInt() and 1 != 0) return null
            val mac = bytes.joinToString(":") { "%02X".format(it.toInt() and 255) }
            return mac.takeUnless { it == "00:00:00:00:00:00" || it == "02:00:00:00:00:00" }
        }

        /** ONVIF only names Baseline, Main, Extended and High, so every High variant reports as High. */
        fun h264ProfileOf(sps: ByteArray): String? {
            if (sps.size < 2 || sps[0].toInt() and 31 != 7) return null
            return when (sps[1].toInt() and 255) {
                66 -> "Baseline"
                77 -> "Main"
                88 -> "Extended"
                100, 110, 122, 244 -> "High"
                else -> null
            }
        }

        fun xml(text: String): String = text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
            .replace("\"", "&quot;").replace("'", "&apos;")

        fun parse(bytes: ByteArray): org.w3c.dom.Document {
            require(bytes.size <= 65536)
            // Accept UTF-8 only. Reject declarations before parsing on Android's
            // XML implementation, which does not support every JAXP feature.
            val text = bytes.toString(Charsets.UTF_8)
            require(!text.contains('\u0000') && !Regex("<!\\s*(DOCTYPE|ENTITY)", RegexOption.IGNORE_CASE).containsMatchIn(text))
            val factory = DocumentBuilderFactory.newInstance().apply { isNamespaceAware = true; isExpandEntityReferences = false }
            val builder = factory.newDocumentBuilder()
            builder.setEntityResolver { _, _ -> throw org.xml.sax.SAXException("External entities are disabled") }
            return builder.parse(ByteArrayInputStream(text.toByteArray(Charsets.UTF_8)))
        }

        fun Element.child(namespace: String, name: String): Element? = (0 until childNodes.length)
            .map { childNodes.item(it) }.filterIsInstance<Element>().firstOrNull { it.namespaceURI == namespace && it.localName == name }

        fun envelope(body: String, action: String? = null) = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
            "<s:Envelope xmlns:s=\"$SOAP\" xmlns:tds=\"$DEVICE\" xmlns:trt=\"$MEDIA\" xmlns:tt=\"$SCHEMA\" " +
            "xmlns:ter=\"http://www.onvif.org/ver10/error\" xmlns:tev=\"$EVENTS\" xmlns:wsnt=\"$NOTIFICATION\" " +
            "xmlns:wsa=\"$ADDRESSING\" xmlns:wstop=\"$TOPICS\" xmlns:tns1=\"http://www.onvif.org/ver10/topics\" " +
            "xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">" +
            (if (action != null) "<s:Header><wsa:Action>$action</wsa:Action></s:Header>" else "") +
            "<s:Body>$body</s:Body></s:Envelope>"
    }
}
