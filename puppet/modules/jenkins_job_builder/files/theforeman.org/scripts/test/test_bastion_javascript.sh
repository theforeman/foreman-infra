#!/bin/bash -xe

npm cache clean
npm install
grunt ci
