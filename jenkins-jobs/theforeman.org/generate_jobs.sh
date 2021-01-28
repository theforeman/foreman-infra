#!/bin/bash

jenkins-jobs -l debug test -r -o /tmp/jobs yaml "$@"
