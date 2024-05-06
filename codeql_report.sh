#!/bin/bash

rm -Rf ./enroll
./codeql/install_codeql.sh && \
  ./codeql/build_db.sh && \
  ./codeql/create_codeql_report.sh && \
  cp -f codeql.json codeql/sarif_html_report/src/data/ &&
  cd codeql/sarif_html_report && \
  npm install && \
  npm run build && \
  open build/index.html
