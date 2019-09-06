#!/bin/bash

result=0

base="$( dirname "${BASH_SOURCE[0]}" )/.."
cd $base
root=`pwd -P`

rm -rf ./log/test.log
rm -rf ./spec/vocabularies
rm -rf ./coverage
rm -rf ./tmp/rspec_junit_*.xml
rm -rf ./public/packs*


[[ -s $HOME/.nvm/nvm.sh ]] && . $HOME/.nvm/nvm.sh
nvm use 10
npm install --global yarn
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

bundle install

bundle exec rails r -e test "DatabaseCleaner.clean"

# Remove coverage for now, it adds about 20 minutes or so
#  COVERAGE=true bundle exec rake parallel:spec[4]
bundle exec rake parallel:spec[4]
