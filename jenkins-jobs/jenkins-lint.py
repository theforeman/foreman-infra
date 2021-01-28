#!/usr/bin/env python

from __future__ import print_function

import argparse
import sys
import lxml.etree
import requests

JENKINS = 'https://ci.theforeman.org'


def get_crumb(session, jenkins):
    url = '{}/crumbIssuer/api/json'.format(jenkins)

    jenkins_crumb_request = session.get(url)
    jenkins_crumb_request.raise_for_status()

    jenkins_crumb_json = jenkins_crumb_request.json()
    jenkins_crumb_field = jenkins_crumb_json['crumbRequestField']
    jenkins_crumb = jenkins_crumb_json['crumb']
    session.headers[jenkins_crumb_field] = jenkins_crumb


def parse_xml(paths):
    for path in sorted(paths):
        jenkins_job = lxml.etree.parse(path)
        content = jenkins_job.xpath("/flow-definition/definition/script/text()")
        if content:
            yield path, content[0]
        else:
            print("{}: No groovy content".format(path))


def parse_jenkinsfile(paths):
    for path in sorted(paths):
        with open(path) as jenkinsfile:
            yield path, jenkinsfile.read()


def validate(session, jenkins, files):
    url = '{}/pipeline-model-converter/validateJenkinsfile'.format(jenkins)

    for path, content in files:
        payload = {
            'jenkinsfile': content,
        }
        validation_result = session.post(url, data=payload)
        validation_result.raise_for_status()

        validation_result_json = validation_result.json()

        if not (validation_result_json['status'] == 'ok' and validation_result_json['data']['result'] == 'success'):
            for err in validation_result_json['data']['errors']:
                print(err)
            print("{}: NOT OK".format(path))
            yield path, validation_result_json['data']['errors']
        else:
            print("{}: OK".format(path))


def main():
    parser = argparse.ArgumentParser(description='lint a Jenkinsfile using a remote Jenkins instance')
    parser.add_argument('jenkinsfile', help='the file to lint', nargs='+')
    parser.add_argument('--jenkins', help='Jenkins URL (default: %(default)s)', default=JENKINS)
    parser.add_argument('--xml', action='store_true', help='treat the Jenkinsfile as an XML job definition')

    args = parser.parse_args()

    if args.xml:
        files = list(parse_xml(args.jenkinsfile))
    else:
        files = list(parse_jenkinsfile(args.jenkinsfile))

    session = requests.Session()
    get_crumb(session, args.jenkins)
    failures = list(validate(session, args.jenkins, files))

    if failures:
        print('Failed to validate files:', file=sys.stderr)
        for path, errors in failures:
            for error in errors:
                print(error, file=sys.stderr)
            print("{}: NOT OK".format(path), file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
