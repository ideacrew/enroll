#!/bin/bash

codeql database create --language ruby --db-cluster --codescanning-config=codeql_strict.yml -- enroll
