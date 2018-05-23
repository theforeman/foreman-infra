#!/bin/bash -xe

cd puppet
rake syntax
rake spec
