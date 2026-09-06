#!/system/bin/sh
# Supplied by the installed APK to ADB. No separate download is needed.
export CLASSPATH=@APK@
ks_helper_uid=@UID@
ks_helper_token=@TOKEN@
ks_helper_main=me.jxl.kiosk_satellite.updates.UpdateHelper
ks_helper_log=/data/local/tmp/ks-update-helper-$ks_helper_uid.log
ks_helper_name=ks-update-helper-$ks_helper_uid

ks_helper_status() {
    app_process /system/bin "$ks_helper_main" status "$ks_helper_uid" "$ks_helper_token" 2>/dev/null
}

if ks_helper_status; then
    echo 'Kiosk Satellite update helper is already running.'
    exit 0
fi

# Recover an older protocol or a secret reset by clearing app data. The
# exact process name limits this to the helper for this Android user.
for ks_helper_pid in $(pidof "$ks_helper_name"); do
    kill "$ks_helper_pid" || exit 1
done

umask 077
nohup app_process /system/bin --nice-name="$ks_helper_name" "$ks_helper_main" serve \
    "$ks_helper_uid" "$ks_helper_token" >"$ks_helper_log" 2>&1 </dev/null &

ks_helper_attempt=0
while [ "$ks_helper_attempt" -lt 5 ]; do
    sleep 1
    if ks_helper_status; then
        echo 'Kiosk Satellite update helper started. Run this command again after a reboot.'
        exit 0
    fi
    ks_helper_attempt=$((ks_helper_attempt + 1))
done
echo "Could not start the update helper. See $ks_helper_log on the device."
exit 1
