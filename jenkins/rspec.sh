#!/bin/bash
 
result=0

base="$( dirname "${BASH_SOURCE[0]}" )/.."

cd $base
root=`pwd -P`

nvm use
yarn install
NODE_ENV=test RAILS_ENV=test ./bin/webpack

for test_dir in `ls -1 $root/components/ | grep -v old_sponsored_benefits`; do
  echo $root/components/$test_dir
  cd $root/components/$test_dir
  bundle install
  bundle exec rspec --fail-fast
  ((result+=$?))
  if [ $result -ne 0 ]; then
    echo "ENGINE FAILED"
	  exit $result
  fi
done

cd $root

rm -Rf ./coverage
rm -Rf ./tmp/rspec_junit_*.xml
bundle install
COVERAGE=true bundle exec rake parallel:spec[4]
