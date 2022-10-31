  CREATE TABLE "SIGNALX"."TRADES" 
   (    "BUYTIME" DATE, 
    "BUYPRICE" NUMBER, 
    "SELLPRICE" NUMBER, 
    "QUANTITY" NUMBER(10,0), 
    "SELLTIME" DATE, 
    "STRATEGY" VARCHAR2(50 BYTE) COLLATE "USING_NLS_COMP", 
    "NAME" VARCHAR2(20 BYTE) COLLATE "USING_NLS_COMP", 
    "TAG" VARCHAR2(20 BYTE) COLLATE "USING_NLS_COMP", 
    "TRADINGSYMBOL" VARCHAR2(30 BYTE) COLLATE "USING_NLS_COMP", 
    "PRODUCT" VARCHAR2(10),
    "creation_date" DATE,
    "LAST_UPDATED_date" DATE,
    "PROFITS" NUMBER(10,2) GENERATED ALWAYS AS (("SELLPRICE"-"BUYPRICE")*"QUANTITY") VIRTUAL , 
    "CHARGES" NUMBER GENERATED ALWAYS AS (CASE  WHEN INSTR("TRADINGSYMBOL",'FUT')>0 THEN ROUND(50+0.0000236*"QUANTITY"*("BUYPRICE"+"SELLPRICE")+0.0001*"SELLPRICE"*"QUANTITY"+0.00002*"BUYPRICE"*"QUANTITY",2) ELSE ROUND(0.00063*"QUANTITY"*("SELLPRICE"+"BUYPRICE")+50+0.0005*"QUANTITY"*"SELLPRICE",2) END) VIRTUAL , 
    "ID" NUMBER(*,0) GENERATED ALWAYS AS IDENTITY MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE 
   )  DEFAULT COLLATION "USING_NLS_COMP" SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 10 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "DATA" ;
--------------------------------------------------------
--  DDL for Index TRADE_IND01
--------------------------------------------------------

  CREATE INDEX "SIGNALX"."TRADE_IND01" ON "SIGNALX"."TRADES" ("TAG") 
  PCTFREE 10 INITRANS 20 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "DATA" ;
--------------------------------------------------------
--  Constraints for Table TRADES
--------------------------------------------------------

--------------------------------------------------------
--  DDL for Table SHARE_TRANSACTIONS
--------------------------------------------------------

  CREATE TABLE "SIGNALX"."SHARE_TRANSACTIONS" 
   (    "ID" NUMBER GENERATED ALWAYS AS IDENTITY MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE , 
    "TRADINGSYMBOL" VARCHAR2(50 BYTE) COLLATE "USING_NLS_COMP", 
    "TRANSACTION_TYPE" VARCHAR2(10 BYTE) COLLATE "USING_NLS_COMP", 
    "QUANTITY" NUMBER, 
    "PRICE" NUMBER, 
    "ORDERDATE" DATE
   )  DEFAULT COLLATION "USING_NLS_COMP" SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 10 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "DATA" ;
--------------------------------------------------------
--  Constraints for Table SHARE_TRANSACTIONS
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Table ACCESS_TOKENS
--------------------------------------------------------

  CREATE TABLE "SIGNALX"."ACCESS_TOKENS" 
   (        "ID" NUMBER(*,0) GENERATED ALWAYS AS IDENTITY MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE,
    "ACCESS_TOKEN" VARCHAR2(40 BYTE) COLLATE "USING_NLS_COMP", 
    "CREATION_DATE" TIMESTAMP (6) DEFAULT systimestamp
   )  DEFAULT COLLATION "USING_NLS_COMP" SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 10 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "DATA" ;

DECLARE
    collection  SODA_Collection_T;
 
BEGIN

    collection := DBMS_SODA.create_collection('dailyplan');   --Stores the daily executed plans
    collection := DBMS_SODA.create_collection('trade_plans');   --Stores the daily saved plans

  ORDS.enable_schema(
    p_enabled             => TRUE,
    p_schema              => 'SIGNALX',
    p_url_mapping_type    => 'BASE_PATH',
    p_url_mapping_pattern => 'signalx',
    p_auto_rest_auth      => FALSE
  );
  COMMIT;
END;
/


create or replace PROCEDURE SIGNALX.CREATE_TRADES(l_clob IN CLOB) as
l_trades json_array_t;
l_trade_obj     JSON_OBJECT_T;
l_date DATE;
l_quantity NUMBER;
l_tradingSymbol VARCHAR2(40);
L_TAG trades.tag%type;
l_txnType VARCHAR2(10);
l_price NUMBER(22,14);
l_status VARCHAR2(20);
l_exchange VARCHAR2(10);
l_tradeiD number;
l_product TRADES.PRODUCT%TYPE;
l_cnt NUMBER:=0;
BEGIN
l_trades:=JSON_ARRAY_T.parse(l_clob);

for indx in 0..l_trades.get_size-1
loop
    l_trade_obj:=TREAT (l_trades.get (indx) AS json_object_t);
    l_quantity:=l_trade_obj.get_Number('quantity');
    l_status:=l_trade_obj.get_String('status');
    l_exchange:=l_trade_obj.get_String('exchange');
    l_tradingSymbol:=l_trade_obj.get_String('tradingsymbol');
    l_txnType:=l_trade_obj.get_String('transaction_type');
    L_TAG:=l_trade_obj.get_String('tag');
    l_price:=l_trade_obj.get_Number('average_price');
    l_product:=l_trade_obj.get_String('product');
    l_date:=TO_DATE( l_trade_obj.get_String('exchange_update_timestamp'),'YYYY-MM-DD HH24:MI:SS');
    CONTINUE WHEN (l_status<>'COMPLETE' );
/*Checking if order is already placed */
    IF l_exchange='NFO' THEN 
        select count(1) INTO
        l_cnt FROM TRADES where quantity=l_quantity
                and TRADINGSYMBOL=l_tradingSymbol
                AND ((l_txnType='BUY' and buyprice IS NOT NULL
                      AND TRUNC(BUYTIME,'MI')=trunc(l_date,'MI'))
                      OR
                      (l_txnType='SELL' and SELLPRICE IS NOT NULL
                      AND TRUNC(SELLTIME,'MI')=trunc(l_date,'MI')));
        if l_cnt=1 THEN
            continue;
        END IF;
        begin
            select id INTO l_tradeiD
            FROM TRADES
            WHERE quantity=l_quantity
                and TRADINGSYMBOL=l_tradingSymbol
                AND ( L_TAG IS NULL OR tag='bsk' OR tag=L_TAG )
                AND ((buyprice is NULL and l_txnType='BUY'
                     AND SELLPRICE IS not NULL)
                     or
                     (SELLPRICE is NULL and l_txnType='SELL'
                     AND  buyprice IS not NULL));
        EXCEPTION
        WHEN others then
        L_TRADEID:=-1;

        end;
        IF L_TRADEID=-1 THEN
            INSERT INTO TRADES(BUYTIME,
            BUYPRICE,
            SELLTIME,
            SELLPRICE,
            QUANTITY,
            TAG,
            tradingsymbol,
            product,
name,
creation_date)
            VALUES
            (CASE WHEN l_txnType='BUY'
                                 THEN l_date
                                 else null end,
            CASE WHEN l_txnType='BUY'
                                 THEN round(l_price,2)
                                 else null END,
            CASE WHEN l_txnType='SELL'
                                 THEN l_date
                                 else null end,
            CASE WHEN l_txnType='SELL'
                                 THEN round(l_price,2)
                                 else null END,
           l_quantity,
           L_TAG,
           l_tradingSymbol,
           l_product,
CASE WHEN instr(l_tradingSymbol,'FUT')>0 THEN 'CMCHASE' ELSE NULL END,
sysdate);
       ELSE
             UPDATE TRADES    
            SET
            buytime=CASE WHEN l_txnType='BUY'
                                 THEN l_date
                                 else buytime END,
                       buyprice=CASE WHEN l_txnType='BUY'
                                 THEN round(l_price,2)
                                 else buyprice END,
                       sellprice=CASE WHEN l_txnType='SELL'
                                 THEN round(l_price,2)
                                 else sellprice END,
                       selltime=CASE WHEN l_txnType='SELL'
                                 THEN l_date
                                 else selltime END   ,
            TRADES.LAST_UPDATED_DATE=sysdate 
            WHERE ID=L_TRADEID;

       END IF;  
    ELSE
        insert into share_transactions(tradingsymbol,
                                    transaction_type,
                                    quantity,
                                    price,
                                    orderDate)
                    VALUES (l_tradingSymbol,
                            l_txnType,
                            l_quantity,
                            ROUND(l_price,2),
                            l_date);
    END IF;

end loop;

/*delete from access_tokens where creation_date<sysdate-5;
UPDATE trades t1 set strategy='NF920' WHERE SUBSTR(t1.tradingsymbol,1,4)='NIFT'
and to_char(t1.selltime,'HH24MI') between '0920' and '1000' and strategy is null
AND (select count(1) from trades T2  WHERE t2.tag=t1.tag 
    and trunc(t2.selltime,'MI')=trunc(t1.selltime,'MI'))=2;

UPDATE trades t1 set strategy='NF1230' WHERE SUBSTR(t1.tradingsymbol,1,4)='NIFT'
and to_char(t1.selltime,'HH24MI') between '1200' and '1300' and strategy is null
AND (select count(1) from trades T2  WHERE t2.tag=t1.tag 
    and trunc(t2.selltime,'MI')=trunc(t1.selltime,'MI'))=2;

UPDATE trades t1 set strategy='NF920' WHERE SUBSTR(t1.tradingsymbol,1,4)='NIFT'
and to_char(t1.selltime,'HH24MI') between '0919' and '1000' and strategy is null
AND (select count(1) from trades T2  WHERE t2.tag=t1.tag 
    and trunc(t2.selltime,'MI')=trunc(t1.selltime,'MI'))=2;

UPDATE trades t1 set strategy='BNF920' WHERE SUBSTR(t1.tradingsymbol,1,4)='BANK'
and to_char(t1.selltime,'HH24MI') between '0919' and '1000' and strategy is null
AND (select count(1) from trades T2  WHERE t2.tag=t1.tag 
    and trunc(t2.selltime,'MI')=trunc(t1.selltime,'MI')
    and substr(t1.tradingsymbol,1,length(t1.tradingsymbol)-2)=
    substr(t2.tradingsymbol,1,length(t2.tradingsymbol)-2))=2;    

UPDATE trades t1 set strategy='BNF1230' WHERE SUBSTR(t1.tradingsymbol,1,4)='BANK'
and to_char(t1.selltime,'HH24MI') between '1200' and '1300' and strategy is null
AND (select count(1) from trades T2  WHERE t2.tag=t1.tag 
    and trunc(t2.selltime,'MI')=trunc(t1.selltime,'MI')
    and substr(t1.tradingsymbol,1,length(t1.tradingsymbol)-2)=
    substr(t2.tradingsymbol,1,length(t2.tradingsymbol)-2))=2;        
*/

 /*collection := DBMS_SODA.open_collection('dailyplan');

    -- Define the filter specification
    qbe := '{"expiresAt" : { "$lt" : "'||TO_CHAR(SYSDATE -2,'YYYY-MM-DD')||'" } }';

    -- Get a count of all documents in the collection that match the QBE
    num_docs := collection.find().filter(qbe).remove;
 */
delete
FROM
  dailyplan
WHERE
    JSON_EXISTS ( "JSON_DOCUMENT" , '$.dayparam
?(@< $B0)' PASSING TO_CHAR(SYSDATE -3,'YYYYMMDD') AS "B0");

update trades set (name,strategy)
=(SELECT
json_value(json_document,'$.name' ) ,json_value(json_document,'$.strategy' )
FROM
dailyplan
WHERE JSON_VALUE(json_document,'$.orderTag' ) =tag
)
where exists ( select 1 from dailyplan
Where JSON_VALUE(json_document,'$.orderTag' ) =tag) and strategy is null;


end CREATE_TRADES;
/


BEGIN
  ords.delete_privilege_mapping(
    'oracle.soda.privilege.developer',
    '/soda/*');

ORDS.DEFINE_MODULE(
   p_module_name     =>'rest-v1',
   p_base_path     =>  'rest-v1/');

ORDS.define_template(
   p_module_name    => 'rest-v1',
   p_pattern        => 'access_tokens');
    
   -- Define service: Creates module, template and handler in a single shot
  ORDS.DEFINE_HANDLER(
    p_module_name    => 'rest-v1',
    p_pattern        => 'access_tokens',
    p_method         => 'GET',
    p_source_type    => ORDS.source_type_collection_feed,
    p_source         => 'SELECT * FROM access_tokens order by creation_date desc',
    p_items_per_page => 0);
    
    
  ORDS.DEFINE_HANDLER(
    p_module_name    => 'rest-v1',
    p_pattern        => 'access_tokens',
    p_method         => 'POST',
    p_source_type    => ORDS.source_type_plsql,
    p_source         => 'BEGIN
                           insert into access_tokens(access_token)
                           values(:access_token);
                         COMMIT;
                         END;
                           ',
    p_items_per_page => 0);    
 ORDS.define_template(
   p_module_name    => 'rest-v1',
   p_pattern        => 'profits/:tag');
   
   ORDS.DEFINE_HANDLER(
      p_module_name    => 'rest-v1',
      p_pattern        => 'profits/:tag',
      p_method         => 'GET',
      p_source_type    => ORDS.source_type_query_one_row,
      p_items_per_page =>  0,
      p_comments       => NULL,
      p_source         => 
'SELECT sum(profits) - sum(charges) as profit from trades where tag=:tag'
      );
 
COMMIT;
    
END;
/

