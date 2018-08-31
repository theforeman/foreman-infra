#!/usr/bin/env python

from __future__ import print_function

import argparse
import sys
import lxml.etree
import requests

JENKINS='https://ci.theforeman.org'

parser = argparse.ArgumentParser(description='lint a Jenkinsfile using a remote Jenkins instance')
parser.add_argument('jenkinsfile', help='the file to lint')
parser.add_argument('--jenkins', help='Jenkins URL (default: %(default)s)', default=JENKINS)
parser.add_argument('--xml', action='store_true', help='treat the Jenkinsfile as an XML job definition')

args = parser.parse_args()

JENKINS_VALIDATE='{}/pipeline-model-converter/validateJenkinsfile'.format(args.jenkins)
JENKINS_CRUMB_ISSUER='{}/crumbIssuer/api/json'.format(args.jenkins)

if args.xml:
    jenkins_job = lxml.etree.parse(args.jenkinsfile)
    jenkins_pipeline = jenkins_job.xpath("/flow-definition/definition/script/text()")[0]
else:
    with open(args.jenkinsfile) as jenkinsfile:
        jenkins_pipeline = jenkinsfile.read()


jenkins_crumb_request = requests.get(JENKINS_CRUMB_ISSUER)
if jenkins_crumb_request.status_code == requests.codes.ok:
    jenkins_crumb_json = jenkins_crumb_request.json()
    jenkins_crumb_field = jenkins_crumb_json['crumbRequestField']
    jenkins_crumb = jenkins_crumb_json['crumb']
    headers = {jenkins_crumb_field: jenkins_crumb}
else:
    headers = {}


payload = {
  'jenkinsfile': jenkins_pipeline
}
validation_result = requests.post(JENKINS_VALIDATE, headers=headers, data=payload)
validation_result.raise_for_status()

validation_result_json = validation_result.json()

if not (validation_result_json['status'] == 'ok' and validation_result_json['data']['result'] == 'success'):
    for err in validation_result_json['data']['errors']:
        print(err)
    print("{}: NOT OK".format(args.jenkinsfile))
    sys.exit(1)
else:
    print("{}: OK".format(args.jenkinsfile))
