sqlplus -s signalx/${db_pwd}@${conn_string}<<EOF
@create_objects.sql
EOF
