#!/usr/bin/env python3
"""Test Terraform's actual mock-rendered patterns through AWS's read-only matcher.

terraform test -test-directory=tftests -filter=tftests/notification_delivery.tftest.hcl \
    -json -verbose > /tmp/ecs-notification-tests.jsonl
python3 tests/test_failure_patterns.py /tmp/ecs-notification-tests.jsonl --profile <read-only-profile>
No events are published and no resources or notifications are created.
"""
import argparse
import copy
import json
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('terraform_test_jsonl')
parser.add_argument('--profile', required=True)
parser.add_argument('--region', default='us-west-2')
args = parser.parse_args()
patterns = {}
with open(args.terraform_test_jsonl) as source:
    for line in source:
        record = json.loads(line)
        if record.get('type') == 'test_state':
            for resource in record['test_state']['root_module']['resources']:
                for name in ('task_failure', 'task_stopped'):
                    if resource['address'] == f'aws_cloudwatch_event_rule.ecs_{name}':
                        patterns[name] = json.loads(resource['values']['event_pattern'])
assert set(patterns) == {'task_failure', 'task_stopped'}, 'mock-applied notification patterns required'
cluster = patterns['task_failure']['detail']['clusterArn'][0]
base = {
    'version': '0', 'id': '11111111-1111-1111-1111-111111111111',
    'detail-type': 'ECS Task State Change', 'source': 'aws.ecs',
    'account': cluster.split(':')[4], 'time': '2026-10-03T02:14:12Z', 'region': args.region,
    'resources': [], 'detail': {
        'clusterArn': cluster, 'lastStatus': 'STOPPED', 'group': 'family:mgb-test-fabric-auth',
        'stopCode': 'EssentialContainerExited', 'stoppedReason': 'Essential container in task exited',
        'containers': [{'name': 'auth', 'exitCode': 0}],
    },
}
cases = [
    ('successful scheduled command', {}, (False, False)),
    ('scheduled nonzero exit', {'containers': [{'name': 'auth', 'exitCode': 1}]}, (True, True)),
    ('nonzero exit among multiple containers', {'containers': [{'name': 'auth', 'exitCode': 0},
                                                              {'name': 'worker', 'exitCode': 137}]}, (True, True)),
    ('essential exit with unknown exit code', {'containers': [{'name': 'auth'}]}, (True, False)),
    ('essential exit without container metadata', {'containers': []}, (True, False)),
    ('startup failure without exit code', {'stopCode': 'TaskFailedToStart',
                                         'stoppedReason': 'ResourceInitializationError', 'containers': []}, (True, False)),
    ('unexpected service stop with exit zero', {'group': 'service:mgb-test-fabric-auth'}, (True, False)),
    ('unexpected service nonzero exit', {'group': 'service:mgb-test-fabric-auth',
                                       'containers': [{'name': 'auth', 'exitCode': 1}]}, (True, True)),
    ('infrastructure termination', {'stopCode': 'SpotInterruption',
                                   'stoppedReason': 'Your Spot Task was interrupted', 'containers': []}, (True, False)),
    ('routine scaling', {'group': 'service:mgb-test-fabric-auth', 'stopCode': 'ServiceSchedulerInitiated',
                        'stoppedReason': 'Scaling activity initiated by deployment ecs-svc/123'}, (False, False)),
    ('other cluster failure', {'clusterArn': cluster + '-other',
                               'containers': [{'name': 'auth', 'exitCode': 1}]}, (False, False)),
    ('running task', {'lastStatus': 'RUNNING', 'containers': [{'name': 'auth', 'exitCode': 1}]}, (False, False)),
]
for label, changes, expected in cases:
    event = copy.deepcopy(base)
    event['detail'].update(changes)
    for name, match in zip(('task_failure', 'task_stopped'), expected):
        result = subprocess.run([
            'aws', '--profile', args.profile, '--region', args.region, 'events', 'test-event-pattern',
            '--event-pattern', json.dumps(patterns[name]), '--event', json.dumps(event),
        ], capture_output=True, check=False)
        assert result.returncode == 0, f'AWS matcher request failed for {label}/{name}'
        assert json.loads(result.stdout)['Result'] is match, f'wrong match for {label}/{name}'
    print(f'PASS: {label}')
print('24 native EventBridge pattern checks passed; no event published.')
