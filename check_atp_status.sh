#!/bin/bash

if [ -z "$ocid_comp" ] 
then
  echo "Error: missing variable definitions"
  exit 1
fi

# Create ATP (Free)
oci db autonomous-database list -c ${ocid_comp} --query 'data[].["display-name","lifecycle-state"]'