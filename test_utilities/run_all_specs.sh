#!/bin/bash
 
result=0

base="$( dirname "${BASH_SOURCE[0]}" )/.."

cd $base

root=`pwd -P`

for test_dir in `ls -1 $root/components/ | grep -v old_sponsored_benefits`; do
  echo $root/components/$test_dir
  cd $root/components/$test_dir
  bundle install
  bundle exec rspec 
done

cd $root
bundle exec rake parallel:spec[4]
