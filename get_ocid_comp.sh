#!/bin/bash

if [ -z "$comp_name" ]
then
  echo "Error: missing variable definitions"
  exit 1
fi

# Get Compartment OCID
# ocid_comp=$(oci iam compartment list --query "data [?\"name\"=='${comp_name}'] | [0].id" --raw-output)
# Solves access and subcompartment issue. Thanks Tim Trauernicht @ Oracle for the fix
ocid_comp=$(oci iam compartment list --access-level ACCESSIBLE --compartment-id-in-subtree TRUE --all --query $oci_comp "data [?\"name\"=='${comp_name}'] | [0].id" --raw-output)

echo "Compartment OCID: " ${ocid_comp}
