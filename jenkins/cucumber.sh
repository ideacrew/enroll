#!/bin/bash

base="$( dirname "${BASH_SOURCE[0]}" )/.."

cd $base
root=`pwd -P`

rm -Rf ./public/packs*

bundle exec cucumber