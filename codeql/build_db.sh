#!/bin/bash

codeql database create --language ruby,javascript --db-cluster --codescanning-config=codeql.yml -- enroll
