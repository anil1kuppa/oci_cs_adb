#!/bin/bash
export db_name=

ocid_comp=$(oci iam availability-domain list --all | jq -r '.data[0]."compartment-id"')   ##Default compartmentId
echo "DB Password :" ; read -s db_pwd; export db_pwd    # Read the password for the ADB.                                                         
export display_name=${db_name}                          # The display name of the ADB instance
export wallet_file=${db_name}                           # The filename of the Wallet
export wallet_pwd=${db_pwd}                             # The password for the Wallet
export TNS_ADMIN=${HOME}/network/admin                  # TNS_ADMIN
export conn_string=${db_name}_LOW                       # Connection string for testing

# NOTE: Password must be 12 to 30 characters and contain at least one uppercase letter, one lowercase letter, 
# and one number. The password cannot contain the double quote (") character or the username "admin".

echo "Database Name    :" ${db_name}
echo "Database Password:" ${db_pwd}
echo "TNS Conn String  :" ${conn_string}
