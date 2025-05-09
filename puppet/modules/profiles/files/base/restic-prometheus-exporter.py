#!/usr/bin/env python3

import json
import os
import subprocess
import sys

import dateutil.parser

from prometheus_client import CollectorRegistry, Gauge, generate_latest

def main():
    restic_bin = os.environ.get('RESTIC_BIN', 'restic')
    restic_repository = os.environ.get('RESTIC_REPOSITORY', 'unknown')

    cmd = [restic_bin, 'snapshots', '--latest', '1', '--json']

    try:
        restic_result = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as e:
        print(f'Failed to run {" ".join(cmd)}: {e.output.decode()}', file=sys.stderr)
        sys.exit(1)
    except IOError as e:
        print(f'Failed to run {" ".join(cmd)}: {e}', file=sys.stderr)
        sys.exit(1)

    snapshots = json.loads(restic_result)

    registry = CollectorRegistry()
    label_names = ['repository', 'hostname', 'paths']

    timestamp = Gauge('restic_snapshot_timestamp_seconds', "Restic snapshot timestamp", label_names, registry=registry)
    size = Gauge('restic_snapshot_size_bytes', "Restic snapshot size", label_names, registry=registry)

    for snapshot in snapshots:
        labels = [restic_repository, snapshot['hostname'], ','.join(snapshot['paths'])]

        timestamp.labels(*labels).set(dateutil.parser.parse(snapshot['time']).timestamp())

        # summary is a restic 0.17+ feature
        if summary := snapshot.get('summary') is not None:
            size.labels(*labels).set(summary.get('total_bytes_processed'))

    print(generate_latest(registry).decode(), end='')

if __name__ == "__main__":
    main()
