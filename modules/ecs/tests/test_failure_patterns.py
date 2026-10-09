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
addresses = {
    'aws_cloudwatch_event_rule.ecs_service_task_failure["auth"]': 'service_task_failure',
    'aws_cloudwatch_event_rule.ecs_standalone_task_failure[0]': 'standalone_task_failure',
}
patterns = {}
with open(args.terraform_test_jsonl) as source:
    for line in source:
        record = json.loads(line)
        if record.get('type') == 'test_state':
            for resource in record['test_state']['root_module']['resources']:
                if resource['address'] in addresses:
                    patterns[addresses[resource['address']]] = json.loads(resource['values']['event_pattern'])
assert set(patterns) == {'service_task_failure', 'standalone_task_failure'}, 'mock-applied notification patterns required'
cluster = patterns['service_task_failure']['detail']['clusterArn'][0]
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
    ('scheduled nonzero exit', {'containers': [{'name': 'auth', 'exitCode': 1}]}, (False, True)),
    ('nonzero exit among multiple containers', {'containers': [{'name': 'auth', 'exitCode': 0},
                                                              {'name': 'worker', 'exitCode': 137}]}, (False, True)),
    ('essential exit with unknown exit code', {'containers': [{'name': 'auth'}]}, (False, True)),
    ('essential exit without container metadata', {'containers': []}, (False, True)),
    # EventBridge exists:false applies across the array, not to each element.
    ('mixed unknown and zero native matching limit', {'containers': [{'name': 'auth'},
                                                                    {'name': 'worker', 'exitCode': 0}]}, (False, False)),
    ('startup failure without exit code', {'stopCode': 'TaskFailedToStart',
                                         'stoppedReason': 'ResourceInitializationError', 'containers': []}, (False, True)),
    ('unexpected service stop with exit zero', {'group': 'service:mgb-test-fabric-auth'}, (True, False)),
    ('unexpected service nonzero exit', {'group': 'service:mgb-test-fabric-auth',
                                       'containers': [{'name': 'auth', 'exitCode': 1}]}, (True, False)),
    ('infrastructure termination', {'stopCode': 'SpotInterruption',
                                   'stoppedReason': 'Your Spot Task was interrupted', 'containers': []}, (False, False)),
    ('routine scaling', {'group': 'service:mgb-test-fabric-auth', 'stopCode': 'ServiceSchedulerInitiated',
                        'stoppedReason': 'Scaling activity initiated by deployment ecs-svc/123'}, (False, False)),
    ('service Spot interruption', {'group': 'service:mgb-test-fabric-auth', 'stopCode': 'SpotInterruption'}, (False, False)),
    ('another service', {'group': 'service:mgb-test-fabric-other'}, (False, False)),
    ('planned ECS host maintenance', {'group': 'service:mgb-test-fabric-auth',
                                      'stopCode': 'ServiceSchedulerInitiated',
                                      'stoppedReason': 'Service mgb-test-fabric-auth: ECS is performing maintenance on the underlying infrastructure hosting the task'}, (False, False)),
    ('service health replacement', {'group': 'service:mgb-test-fabric-auth', 'stopCode': 'ServiceSchedulerInitiated', 'stoppedReason': 'Task failed ELB health checks'}, (True, False)),
    ('other cluster failure', {'clusterArn': cluster + '-other',
                               'containers': [{'name': 'auth', 'exitCode': 1}]}, (False, False)),
    ('service missing stopCode', {'group': 'service:mgb-test-fabric-auth', 'stopCode': None}, (False, False)),
    ('standalone missing stopCode', {'stopCode': None, 'containers': [{'exitCode': 1}]}, (False, False)),
    ('missing group', {'group': None, 'containers': [{'exitCode': 1}]}, (False, False)),
    ('running task', {'lastStatus': 'RUNNING', 'containers': [{'name': 'auth', 'exitCode': 1}]}, (False, False)),
]
for label, changes, expected in cases:
    event = copy.deepcopy(base)
    event['detail'].update(changes)
    for key, value in changes.items():
        if value is None:
            del event['detail'][key]
    for name, match in zip(('service_task_failure', 'standalone_task_failure'), expected):
        result = subprocess.run([
            'aws', '--profile', args.profile, '--region', args.region, 'events', 'test-event-pattern',
            '--event-pattern', json.dumps(patterns[name]), '--event', json.dumps(event),
        ], capture_output=True, check=False)
        assert result.returncode == 0, f'AWS matcher request failed for {label}/{name}'
        assert json.loads(result.stdout)['Result'] is match, f'wrong match for {label}/{name}'
    print(f'PASS: {label}')
print(f'{len(cases) * 2} native EventBridge pattern checks passed; no event published.')
