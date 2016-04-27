#!/bin/bash -xe

pushd plugin
npm cache clean
npm install
grunt ci
