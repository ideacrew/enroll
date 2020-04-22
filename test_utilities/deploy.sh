#!/bin/bash

regex='refs/heads/(.*)'
[[ "$BRANCH" =~ $regex ]]
SIMPLE_BRANCH=${BASH_REMATCH[1]}

$DEPLOY_CMD "branch=${BRANCH}" --data-urlencode "status=${STATUS}"
