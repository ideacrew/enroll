#!/bin/bash

codeql database analyze --format=sarif-latest --output=codeql.sarif --sarif-add-snippets -- enroll/ruby
