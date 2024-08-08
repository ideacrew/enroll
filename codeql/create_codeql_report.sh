#!/bin/bash

codeql database analyze --format=sarif-latest --output=codeql-ruby.sarif --sarif-add-snippets -- enroll/ruby
codeql database analyze --format=sarif-latest --output=codeql-js.sarif --sarif-add-snippets -- enroll/javascript
codeql github merge-results --sarif=codeql-js.sarif --sarif=codeql-ruby.sarif --output=codeql.sarif