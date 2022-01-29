sqlplus -s signalx/${db_pwd}@${conn_string}<<EOF
DROP TABLE TRADES;
drop table SHARE_TRANSACTIONS;
DROP TABLE ACCESS_TOKENS;
DECLARE
    status  NUMBER := 0;
BEGIN
    status := DBMS_SODA.drop_collection('dailyplan');
    status := DBMS_SODA.drop_collection('trade_plans');
END;
/
DROP PROCEDURE CREATE_TRADES;

EXECUTE ORDS.DELETE_MODULE(p_module_name=>'rest-v1');
/
exit;
EOF

