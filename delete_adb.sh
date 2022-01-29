#!/bin/bash

if [ -z "$adb_id" ] 
then
  echo "Error: missing variable definitions"
  exit 1
fi

oci db autonomous-database delete --autonomous-database-id ${adb_id}