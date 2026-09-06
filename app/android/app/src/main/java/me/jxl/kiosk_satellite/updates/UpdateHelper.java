package me.jxl.kiosk_satellite.updates;

import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Looper;
import android.os.Process;
import android.os.UserHandle;
import android.system.Os;
import android.util.Log;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * An app_process entry point started by ADB as uid 2000. Its lifetime is
 * independent of the app being updated. The endpoint is loopback only and
 * uses a secret supplied through the shell-only bootstrap provider.
 */
public final class UpdateHelper {
    private static final String TAG = "KSUpdateHelper";
    private final int uid;
    private final String token;
    private final PackageManager packages;
    private final File staging;
    private final AtomicBoolean installing = new AtomicBoolean();
    private ServerSocket server;

    private UpdateHelper(int uid, String token) throws Exception {
        this.uid = uid;
        this.token = token;
        // app_process has no Application. Obtain only a framework context,
        // without loading Flutter or starting any of the kiosk's services.
        Looper.prepareMainLooper();
        Class<?> activityThread = Class.forName("android.app.ActivityThread");
        Object thread = activityThread.getMethod("systemMain").invoke(null);
        Context context = (Context) activityThread.getMethod("getSystemContext").invoke(thread);
        if (uid / 100000 != 0) {
            context = (Context) Context.class.getMethod("createContextAsUser", UserHandle.class,
                    int.class).invoke(context, UserHandle.getUserHandleForUid(uid), 0);
        }
        packages = context.getPackageManager();
        if (packages.getApplicationInfo(HelperProtocol.PACKAGE, 0).uid != uid) {
            throw new SecurityException("Kiosk Satellite UID changed. Start the helper again.");
        }
        staging = new File("/data/local/tmp/ks-update-helper-" + uid);
        if (!staging.isDirectory() && !staging.mkdir()) throw new IOException("Cannot create staging directory");
        Os.chmod(staging.getPath(), 0700);
    }

    public static void main(String[] args) throws Exception {
        if (Process.myUid() != 2000 && Process.myUid() != 0) {
            throw new SecurityException("Start the update helper through ADB");
        }
        int uid = Integer.parseInt(args[1]);
        String token = args[2];
        if ("status".equals(args[0])) {
            try (Socket socket = HelperProtocol.connect(uid, token, "PING")) {
                System.out.println(new DataInputStream(socket.getInputStream()).readUTF());
            } catch (IOException e) {
                // An absent helper is an expected bootstrap probe result.
                System.exit(1);
            }
            return;
        }
        if (!"serve".equals(args[0])) throw new IllegalArgumentException("Unknown operation");
        new UpdateHelper(uid, token).serve();
        System.exit(0);
    }

    private void serve() throws Exception {
        server = new ServerSocket();
        server.setReuseAddress(true);
        server.bind(new java.net.InetSocketAddress(InetAddress.getByName("127.0.0.1"),
                HelperProtocol.port(uid)));
        // Another copy cannot bind, so only the active helper cleans up an
        // interrupted upload left by a previous run.
        File[] old = staging.listFiles();
        if (old != null) for (File file : old) if (file.getName().endsWith(".apk")) file.delete();
        ThreadPoolExecutor workers = new ThreadPoolExecutor(4, 4, 30, TimeUnit.SECONDS,
                new ArrayBlockingQueue<>(4));
        workers.allowCoreThreadTimeOut(true);
        Log.i(TAG, "ready for Kiosk Satellite uid " + uid);
        try {
            while (!server.isClosed()) {
                Socket socket = server.accept();
                try { workers.execute(() -> handle(socket)); }
                catch (java.util.concurrent.RejectedExecutionException e) { socket.close(); }
            }
        } catch (java.net.SocketException e) {
            if (!server.isClosed()) throw e;
        } finally {
            workers.shutdownNow();
            server.close();
        }
    }

    private void handle(Socket socket) {
        try (Socket connection = socket) {
            connection.setSoTimeout(1500);
            DataInputStream in = new DataInputStream(connection.getInputStream());
            DataOutputStream out = new DataOutputStream(connection.getOutputStream());
            if (!HelperProtocol.MAGIC.equals(in.readUTF())) return;
            String challenge = in.readUTF();
            if (challenge.length() != 36) return;
            String serverChallenge = java.util.UUID.randomUUID().toString();
            challenge += ":" + serverChallenge;
            out.writeUTF(HelperProtocol.MAGIC);
            out.writeUTF(serverChallenge);
            out.writeUTF(HelperProtocol.proof(token, "server", challenge));
            out.flush();
            if (!HelperProtocol.authentic(HelperProtocol.proof(token, "client", challenge),
                    in.readUTF())) return;
            String operation = in.readUTF();
            out.writeUTF(HelperProtocol.MAGIC);
            out.flush();
            if ("PING".equals(operation)) {
                out.writeUTF(installing.get() ? "busy" : "ready");
            } else if ("STOP".equals(operation)) {
                if (!installing.compareAndSet(false, true)) {
                    out.writeUTF("busy");
                } else {
                    out.writeUTF("stopped");
                    out.flush();
                    server.close();
                }
            } else if ("INSTALL".equals(operation)) {
                if (!installing.compareAndSet(false, true)) {
                    out.writeUTF("busy");
                } else {
                    try { install(connection, in, out); }
                    finally { installing.set(false); }
                }
            } else {
                out.writeUTF("Unsupported helper operation");
            }
            out.flush();
        } catch (Exception e) {
            Log.w(TAG, "request ended: " + e.getMessage());
        }
    }

    private void install(Socket socket, DataInputStream in, DataOutputStream out) throws Exception {
        File apk = null;
        try {
            out.writeUTF("upload");
            out.flush();
            socket.setSoTimeout(60000);
            long size = in.readLong();
            if (size <= 0 || size > HelperProtocol.MAX_APK_BYTES) throw new IOException("Invalid APK size");
            apk = File.createTempFile("update-", ".apk", staging);
            try (FileOutputStream file = new FileOutputStream(apk)) {
                byte[] buffer = new byte[65536];
                for (long left = size; left > 0;) {
                    int n = in.read(buffer, 0, (int) Math.min(left, buffer.length));
                    if (n < 0) throw new IOException("Incomplete APK upload");
                    file.write(buffer, 0, n);
                    left -= n;
                }
                file.getFD().sync();
            }
            PackageInfo installed = packages.getPackageInfo(HelperProtocol.PACKAGE, 0);
            PackageInfo candidate = packages.getPackageArchiveInfo(apk.getPath(), 0);
            if (candidate == null) throw new IOException("Invalid APK");
            HelperProtocol.validateCandidate(candidate.packageName, version(candidate), version(installed));
            out.writeUTF("prepared");
            out.flush();
            if (!"COMMIT".equals(in.readUTF())) throw new IOException("Install was not committed");
            // Nothing installs before COMMIT. After it, a client disconnect
            // must not trigger a second install through the system dialog.
            out.writeUTF("accepted");
            out.flush();
            Log.i(TAG, "installing Kiosk Satellite version " + version(candidate));
            // PackageManager checks the signing certificate against the
            // installed package. Arguments are fixed, never a shell string.
            java.lang.Process process = new ProcessBuilder("/system/bin/pm", "install", "-r",
                    "--user", Integer.toString(uid / 100000), "-i", HelperProtocol.PACKAGE,
                    apk.getPath()).redirectErrorStream(true).start();
            StringBuilder output = new StringBuilder();
            try (java.io.BufferedReader reader = new java.io.BufferedReader(
                    new java.io.InputStreamReader(process.getInputStream()))) {
                for (String line; (line = reader.readLine()) != null;) {
                    if (output.length() < 8000) output.append(line).append('\n');
                }
            }
            boolean success = process.waitFor() == 0 && output.toString().trim().equals("Success");
            Log.i(TAG, success ? "update installed" : "install failed: " + output);
            out.writeUTF(success ? "installed" : "Install failed: " + output.toString().trim());
        } catch (Exception e) {
            try { out.writeUTF("Install failed: " + e.getMessage()); out.flush(); }
            catch (IOException ignored) { }
            throw e;
        } finally {
            if (apk != null) apk.delete();
        }
    }

    private static long version(PackageInfo info) {
        return Build.VERSION.SDK_INT >= 28 ? info.getLongVersionCode() : info.versionCode;
    }
}
