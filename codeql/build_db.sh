#!/bin/bash

codeql database create --language ruby --language javascript --db-cluster --codescanning-config=codeql.yml -- enroll
