package me.jxl.kiosk_satellite.updates;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.UUID;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

/** The helper has three fixed operations. It never accepts shell commands. */
public final class HelperProtocol {
    public static final String PACKAGE = "me.jxl.kiosk_satellite";
    public static final String MAGIC = "KS_UPDATE_HELPER_2";
    public static final long MAX_APK_BYTES = 1024L * 1024 * 1024;
    public static final int PROBE_TIMEOUT_MS = 750;

    private HelperProtocol() {}

    public static int port(int uid) { return 32000 + uid % 30000; }

    public static Socket connect(int uid, String token, String operation) throws IOException {
        Socket socket = new Socket();
        try {
            socket.connect(new InetSocketAddress("127.0.0.1", port(uid)), PROBE_TIMEOUT_MS);
            socket.setSoTimeout(PROBE_TIMEOUT_MS);
            DataOutputStream out = new DataOutputStream(socket.getOutputStream());
            DataInputStream in = new DataInputStream(socket.getInputStream());
            String challenge = UUID.randomUUID().toString();
            out.writeUTF(MAGIC);
            out.writeUTF(challenge);
            out.flush();
            if (!MAGIC.equals(in.readUTF())) throw new IOException("Incompatible update helper");
            String serverChallenge = in.readUTF();
            challenge += ":" + serverChallenge;
            if (serverChallenge.length() != 36 ||
                    !authentic(proof(token, "server", challenge), in.readUTF())) {
                throw new IOException("Update helper authentication failed");
            }
            out.writeUTF(proof(token, "client", challenge));
            out.writeUTF(operation);
            out.flush();
            String reply = in.readUTF();
            if (!MAGIC.equals(reply)) throw new IOException("Incompatible update helper");
            return socket;
        } catch (IOException e) {
            socket.close();
            throw e;
        }
    }

    public static boolean authentic(String expected, String supplied) {
        return MessageDigest.isEqual(expected.getBytes(StandardCharsets.UTF_8),
                supplied.getBytes(StandardCharsets.UTF_8));
    }

    public static String proof(String token, String side, String challenge) throws IOException {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(token.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] digest = mac.doFinal((side + ":" + challenge).getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder();
            for (byte b : digest) hex.append(String.format("%02x", b & 255));
            return hex.toString();
        } catch (java.security.GeneralSecurityException e) {
            throw new IOException("Cannot authenticate the update helper", e);
        }
    }

    public static void validateCandidate(String packageName, long version, long installedVersion) {
        if (!PACKAGE.equals(packageName)) {
            throw new IllegalArgumentException("The helper only updates Kiosk Satellite");
        }
        if (version < installedVersion) {
            throw new IllegalArgumentException("The helper does not install older versions");
        }
    }
}
