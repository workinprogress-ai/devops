#!/bin/bash

git fetch --tags
latest_tag=$(git tag -l 'v*' | sort -V | tail -n 1)
if [ -z "$latest_tag" ]; then
    echo "0.0.0"
else
    version_only=${latest_tag#v}
    echo $version_only
fi
