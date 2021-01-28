#!/bin/bash

jenkins-jobs --conf ~/.config/jenkins_job.ini update -r jobs/ $1
