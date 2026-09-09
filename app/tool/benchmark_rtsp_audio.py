#!/usr/bin/env python3
"""Compare RTSP audio off and on using Android process CPU and RSS counters."""

import argparse
import json
import os
from pathlib import Path
import statistics
import subprocess
import time
import urllib.request


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--device', required=True, help='Device IP with ADB on port 5555')
    parser.add_argument('--remote-port', type=int, default=2324)
    parser.add_argument('--rtsp-url', help='Override the camera URL, including authentication if needed')
    parser.add_argument('--seconds', type=int, default=45)
    parser.add_argument('--rounds', type=int, default=3)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    if args.seconds < 10 or args.rounds < 1:
        parser.error('Use at least 10 seconds and one round')
    token = os.environ.get('KS_REMOTE_TOKEN')
    if not token:
        parser.error('Set KS_REMOTE_TOKEN to a Remote Admin bearer token')
    args.output.mkdir(parents=True, exist_ok=True)

    def api(path, data=None, method=None):
        request = urllib.request.Request(
            f'http://{args.device}:{args.remote_port}{path}',
            data=None if data is None else json.dumps(data).encode(),
            headers={'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token},
            method=method,
        )
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)

    def command(name):
        result = api('/api/commands/' + name, {})
        if not result.get('ok'):
            raise RuntimeError(f'{name} failed')
        return result['data']

    def adb(code):
        return subprocess.check_output(
            ['adb', '-s', args.device + ':5555', 'shell', code], text=True, timeout=20,
        )

    ticks_per_second = int(adb('getconf CLK_TCK').strip())
    page_size = int(adb('getconf PAGESIZE').strip())
    names = ['me.jxl.kiosk_satellite', 'media.codec', 'media.swcodec', 'audioserver', 'cameraserver']

    def sample():
        # Names are fixed locally. No user input is inserted into shell code.
        raw = adb('cat /proc/uptime; for name in ' + ' '.join(names) +
                  '; do for p in $(pidof $name); do echo $name; cat /proc/$p/stat; done; done')
        lines = raw.splitlines()
        result = {'time': float(lines[0].split()[0]), 'processes': {}}
        for offset in range(1, len(lines), 2):
            stat = lines[offset + 1]
            fields = stat.split(') ', 1)[1].split()
            result['processes'][lines[offset]] = {
                'pid': int(stat.split(' ', 1)[0]),
                'ticks': int(fields[11]) + int(fields[12]),
                'rss_mib': int(fields[21]) * page_size / 1024 / 1024,
            }
        if names[0] not in result['processes']:
            raise RuntimeError('Cannot read app process statistics. Check ADB access')
        return result

    initial = command('getRtspStatus')
    if not initial.get('listening'):
        raise RuntimeError('Enable RTSP streaming on the device before measuring')
    url = args.rtsp_url or f'rtsp://{args.device}:{initial["port"]}/camera'
    original_audio = initial.get('audioEnabled', False)
    reports = []
    try:
        for round_number in range(1, args.rounds + 1):
            for enabled in (False, True):
                label = f'{round_number}-' + ('audio' if enabled else 'video')
                api('/api/settings', {'camera.rtsp.audio': enabled}, 'PATCH')
                time.sleep(4)
                with (args.output / (label + '-ffmpeg.log')).open('w') as log:
                    player = subprocess.Popen(
                        ['ffmpeg', '-nostdin', '-hide_banner', '-loglevel', 'warning',
                         '-rtsp_transport', 'tcp', '-i', url, '-map', '0', '-c', 'copy', '-f', 'null', '-'],
                        stdout=log, stderr=log,
                    )
                    try:
                        time.sleep(12)
                        if player.poll() is not None:
                            raise RuntimeError('RTSP reader exited. Check the FFmpeg log')
                        audio_start = command('getRtspStatus')
                        if enabled and not audio_start.get('audioEncoding'):
                            raise RuntimeError('Audio encoder did not start')
                        samples = [sample()]
                        for _ in range(args.seconds // 5):
                            time.sleep(5)
                            samples.append(sample())
                        audio_end = command('getRtspStatus')
                        elapsed = samples[-1]['time'] - samples[0]['time']
                        processes = {}
                        for name, first in samples[0]['processes'].items():
                            values = [value['processes'][name] for value in samples]
                            if any(value['pid'] != first['pid'] for value in values):
                                raise RuntimeError(f'{name} restarted during the measurement')
                            processes[name] = {
                                'cpu_one_core_percent': (values[-1]['ticks'] - first['ticks']) /
                                    ticks_per_second / elapsed * 100,
                                'mean_rss_mib': statistics.mean(value['rss_mib'] for value in values),
                            }
                        report = {
                            'label': label, 'seconds': elapsed, 'processes': processes,
                            'audio_encoder': audio_end.get('audioEncoder'),
                            'audio_worker_cpu_one_core_percent':
                                (audio_end.get('audioWorkerCpuMs', 0) -
                                 audio_start.get('audioWorkerCpuMs', 0)) / elapsed / 10,
                            'audio_dropped_chunks': audio_end.get('audioDroppedChunks', 0),
                            'wake_state': command('getWakeWordState')['status'],
                            'samples': samples,
                        }
                        reports.append(report)
                        (args.output / 'metrics.json').write_text(json.dumps(reports, indent=2) + '\n')
                        print(json.dumps({key: value for key, value in report.items() if key != 'samples'}), flush=True)
                    finally:
                        player.terminate()
                        try:
                            player.wait(timeout=5)
                        except subprocess.TimeoutExpired:
                            player.kill()
                            player.wait()
    finally:
        api('/api/settings', {'camera.rtsp.audio': original_audio}, 'PATCH')


if __name__ == '__main__':
    main()
