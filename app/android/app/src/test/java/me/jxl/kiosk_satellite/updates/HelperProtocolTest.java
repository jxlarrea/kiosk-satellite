package me.jxl.kiosk_satellite.updates;

import org.junit.Test;
import static org.junit.Assert.*;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.Executors;

public class HelperProtocolTest {
    @Test public void proofBindsSecretChallengeAndDirection() throws Exception {
        String proof = HelperProtocol.proof("secret", "server", "challenge");
        assertTrue(HelperProtocol.authentic(proof,
                HelperProtocol.proof("secret", "server", "challenge")));
        assertFalse(HelperProtocol.authentic(proof,
                HelperProtocol.proof("other", "server", "challenge")));
        assertFalse(HelperProtocol.authentic(proof,
                HelperProtocol.proof("secret", "server", "replay")));
        assertFalse(HelperProtocol.authentic(proof,
                HelperProtocol.proof("secret", "client", "challenge")));
    }

    @Test public void unrelatedPackagesAndDowngradesAreRejected() {
        assertThrows(IllegalArgumentException.class,
                () -> HelperProtocol.validateCandidate("other.package", 300, 200));
        assertThrows(IllegalArgumentException.class,
                () -> HelperProtocol.validateCandidate(HelperProtocol.PACKAGE, 199, 200));
        HelperProtocol.validateCandidate(HelperProtocol.PACKAGE, 200, 200);
        HelperProtocol.validateCandidate(HelperProtocol.PACKAGE, 201, 200);
    }

    @Test public void clientRejectsAnImpersonatingServerBeforeSendingAnOperation() throws Exception {
        // An app that occupies the helper's port cannot learn the secret or
        // receive an install request by merely repeating the protocol magic.
        try (ServerSocket server = helperPort()) {
            int uid = server.getLocalPort() - 32000;
            if (uid < 0) uid += 30000;
            var executor = Executors.newSingleThreadExecutor();
            try {
                var peer = executor.submit(() -> {
                    try (Socket socket = server.accept()) {
                        socket.setSoTimeout(2000);
                        DataInputStream in = new DataInputStream(socket.getInputStream());
                        DataOutputStream out = new DataOutputStream(socket.getOutputStream());
                        assertEquals(HelperProtocol.MAGIC, in.readUTF());
                        String challenge = in.readUTF();
                        assertNotEquals("secret", challenge);
                        out.writeUTF(HelperProtocol.MAGIC);
                        out.writeUTF(java.util.UUID.randomUUID().toString());
                        out.writeUTF("not-a-valid-proof");
                        out.flush();
                        assertEquals(-1, in.read());
                        return true;
                    }
                });
                final int targetUid = uid;
                assertThrows(IOException.class, () -> HelperProtocol.connect(targetUid, "secret", "INSTALL"));
                assertTrue(peer.get());
            } finally { executor.shutdownNow(); }
        }
    }

    private static ServerSocket helperPort() throws IOException {
        for (int port = 52000; port < 52100; port++) {
            try { return new ServerSocket(port); }
            catch (java.net.BindException ignored) { }
        }
        throw new IOException("No test port available");
    }
}
