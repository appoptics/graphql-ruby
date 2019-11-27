#!/bin/bash

##
# This script installs the gems and either starts a bash shell  the tests
# or runs the tests if called with the argument "test"
##

dir=`pwd`
cd /code/ruby-graphql/

rm -f gemfiles/*.lock
rm -f .ruby-version

rbenv global 2.6.4

echo "Installing gems ..."
bundle install

if [ "$1" == "test" ]; then
  echo "Running tests ..."
  bundle exec rake test
else
  /bin/bash
fi

rm -f gemfiles/*.lock
rm -f .ruby-version
cd $dir
