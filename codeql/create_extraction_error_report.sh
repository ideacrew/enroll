#!/bin/bash

codeql database analyze --format=sarif-latest --output=codeql.json --sarif-add-snippets -- enroll/ruby  codeql/ruby-queries:queries/diagnostics/ExtractionErrors.ql
