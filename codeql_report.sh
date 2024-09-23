#!/bin/bash

rm -Rf ./enroll
./codeql/build_db.sh && \
  ./codeql/create_codeql_report.sh && \
  cp -f codeql.sarif codeql/sarif_html_report/src/data/codeql.json &&
  cp -f codeql/ignore.yaml codeql/sarif_html_report/src/data/ignore.yaml &&
  cd codeql/sarif_html_report && \
  npm install && \
  npm run build && \
  open build/index.html
