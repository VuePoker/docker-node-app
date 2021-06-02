#!/bin/bash

os_version=${1-:$(sw_vers -productVersion)}
required_version="$1"
if [ "$(printf '%s\n' "$required_version" "$os_version" | sort -V | head -n1)" = "$required_version" ]; then
   echo "true"
else
   echo "false"
fi