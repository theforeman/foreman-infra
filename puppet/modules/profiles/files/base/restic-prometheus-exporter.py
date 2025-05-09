import json
import subprocess
import sys

import dateutil.parser

from prometheus_client import CollectorRegistry, Gauge, generate_latest

def main():
    cmd = ['restic', 'snapshots', '--latest', '1', '--json']
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

    timestamp = Gauge('restic_snapshot_timestamp_seconds', "Snapshot timestamp", ['hostname', 'paths'], registry=registry)
    for snapshot in snapshots:
        timestamp.labels(snapshot['hostname'], '_'.join(snapshot['paths'])).set(dateutil.parser.parse(snapshot['time']).timestamp())

    size = Gauge('restic_snapshot_size_bytes', "Snapshot size", ['hostname', 'paths'], registry=registry)
    for snapshot in snapshots:
        size.labels(snapshot['hostname'], '_'.join(snapshot['paths'])).set(snapshot['summary']['total_bytes_processed'])

    print(generate_latest(registry).decode(), end='')

if __name__ == "__main__":
    main()
