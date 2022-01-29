#!/bin/bash

if [ -z "$ocid_comp" ] 
then
  echo "Error: missing variable definitions"
  exit 1
fi

# Get SODA URL
echo `oci db autonomous-database list -c ${ocid_comp} --query 'data[0]."connection-urls"."apex-url"'`|sed 's/"//g'|tr '[:upper:]' '[:lower:]'|sed 's/\/[^/]\+$/\/signalx/'
