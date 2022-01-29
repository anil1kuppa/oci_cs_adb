sqlplus -s admin/${db_pwd}@${conn_string}<< EOF
CREATE USER SignalX IDENTIFIED BY "$db_pwd" DEFAULT TABLESPACE data QUOTA UNLIMITED ON data;
GRANT DWROLE TO signalx;
GRANT SODA_APP to signalx;
exit;
EOF
