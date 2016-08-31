#!/bin/bash

jenkins-jobs --conf jenkins_jobs.ini update -r . $1
