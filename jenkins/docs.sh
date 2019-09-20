#!/bin/bash

base="$( dirname "${BASH_SOURCE[0]}" )/.."

cd $base
root=`pwd -P`

rm -Rf ./doc ./rubocop rdocs.zip

bundle exec yardoc
bundle exec rubocop -f h -o rubocop/index.html
zip -r rdocs.zip doc rubocop