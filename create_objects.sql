  create table transactions
(ID NUMBER(*,0) GENERATED ALWAYS AS IDENTITY MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE ,
OrderTime DATE,
TransactionType VARCHAR2(10),
Exchange                    VARCHAR2(10)       ,
TRADINGSYMBOL              VARCHAR2(30) ,
QUANTITY                   NUMBER(10)   ,
AveragePrice NUMBER,
ORDERID NUMBER,
STRATEGY                   VARCHAR2(50) ,
NAME                       VARCHAR2(20) ,
TAG                        VARCHAR2(20) ,
PRODUCT                    VARCHAR2(10) ,
CREATION_DATE              DATE         DEFAULT SYSDATE,
CHARGES NUMBER GENERATED ALWAYS AS (CASE  WHEN TransactionType='BUY' AND Exchange IN ('BFO','NFO') THEN ROUND(25+0.00062*QUANTITY*AveragePrice,2) WHEN TransactionType='SELL' AND Exchange IN ('BFO','NFO') THEN ROUND(25+0.0013*"QUANTITY"*AveragePrice,2) WHEN TransactionType='BUY' AND Exchange IN ('NSE','BSE') AND PRODUCT IN ('MIS','CO') THEN ROUND(23.6+0.00011*"QUANTITY"*AveragePrice,2) WHEN TransactionType='SELL' AND Exchange IN ('NSE','BSE') AND PRODUCT IN ('MIS','CO') THEN ROUND(23.6+0.0003*"QUANTITY"*AveragePrice,2) WHEN TransactionType='BUY' AND Exchange IN ('NSE','BSE') AND PRODUCT='CNC' THEN ROUND(0.0012*"QUANTITY"*AveragePrice,2) WHEN TransactionType='SELL' AND Exchange IN ('NSE','BSE') AND PRODUCT='CNC' THEN  ROUND(16 + 0.0010413*"QUANTITY"*AveragePrice,2) else 50 END) VIRTUAL 
);  
--https://oracle-base.com/articles/11g/virtual-columns-11gr1

--https://docs.oracle.com/cd/E17952_01/mysql-8.0-en/alter-table-generated-columns.html
--------------------------------------------------------
--  DDL for Index TRADE_IND01
--------------------------------------------------------

  CREATE INDEX "SIGNALX"."transactions_IND01" ON TRANSACTIONS ("TAG");
--------------------------------------------------------
--  Constraints for Table TRADES
--------------------------------------------------------


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
L_TAG transactions.tag%type;
l_txnType VARCHAR2(10);
l_price NUMBER(22,14);
l_orderid NUMBER;
l_status VARCHAR2(20);
l_exchange VARCHAR2(10);
l_tradeiD number;
l_product transactions.PRODUCT%TYPE;
l_cnt NUMBER:=0;
BEGIN
l_trades:=JSON_ARRAY_T.parse(l_clob);

for indx in 0..l_trades.get_size-1
loop
    l_trade_obj:=TREAT (l_trades.get (indx) AS json_object_t);
    l_quantity:=l_trade_obj.get_Number('quantity');
    l_orderid:=l_trade_obj.get_Number('order_id');
    l_status:=l_trade_obj.get_String('status');
    l_exchange:=l_trade_obj.get_String('exchange');
    l_tradingSymbol:=l_trade_obj.get_String('tradingsymbol');
    l_txnType:=l_trade_obj.get_String('transaction_type');
    L_TAG:=l_trade_obj.get_String('tag');
    l_price:=l_trade_obj.get_Number('average_price');
    l_product:=l_trade_obj.get_String('product');
    l_date:=TO_DATE( l_trade_obj.get_String('exchange_update_timestamp'),'YYYY-MM-DD HH24:MI:SS');
    CONTINUE WHEN (l_status<>'COMPLETE' );
       
            INSERT INTO transactions(OrderTime,
            TransactionType,
            ORDERID,
            Exchange,
            tradingsymbol,
            QUANTITY,
            AveragePrice,
            TAG,
            product)
            VALUES
            (l_date,
            l_txnType,
            l_orderid,
            l_exchange,
            l_tradingSymbol,
            l_quantity,
            round(l_price,3),
           L_TAG,
           l_product);
    

end loop;

/*delete from access_tokens where creation_date<sysdate-5;

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

update transactions set (name,strategy)
=(SELECT
json_value(json_document,'$.name' ) ,json_value(json_document,'$.strategy' )
FROM
dailyplan
WHERE JSON_VALUE(json_document,'$.orderTag' ) =tag and rownum=1
)
where exists ( select 1 from dailyplan
Where JSON_VALUE(json_document,'$.orderTag' ) =tag) and strategy is null and exchange in ('BFO','NFO');


end CREATE_TRADES;
/

-- Refer https://oracle-base.com/articles/misc/oracle-rest-data-services-ords-restful-web-services-handling-complex-json-payloads

BEGIN
  ords.delete_privilege_mapping(
    'oracle.soda.privilege.developer',
    '/soda/*');

ORDS.DEFINE_MODULE(
   p_module_name     =>'rest-v1',
   p_base_path     =>  'rest-v1/');
    
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
'select round(SUM(CASE WHEN TransactionType=''BUY'' THEN -1*QUANTITY*AveragePrice - charges
    else QUANTITY*AveragePrice - charges end),2) as profits
 from transactions where tag=:tag'
      );
 
     ORDS.define_template(
   p_module_name    => 'rest-v1',
   p_pattern        => 'trades');
 ORDS.define_handler(
    p_module_name    => 'rest-v1',
    p_pattern        => 'trades',
    p_method         => 'POST',
    p_source_type    => ORDS.source_type_plsql,
    p_source         => 'BEGIN
                           create_trades(l_clob => :body_text);
                         END;',
    p_items_per_page => 0);
COMMIT;
END;
/

/*
select json_serialize(json_document) as data from dailyplan
where JSON_VALUE(json_document,'$.orderTag' ) ='6SN7EtGE';
declare
l_clob CLOB;
begin
l_clob:='[
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200143904",
        "exchange_order_id": "2000000001704615",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T03:48:33.000Z",
        "exchange_update_timestamp": "2024-06-07 09:18:33",
        "exchange_timestamp": "2024-06-07T03:48:33.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NFO",
        "tradingsymbol": "NIFTY2461322650PE",
        "instrument_token": 11237378,
        "order_type": "MARKET",
        "transaction_type": "BUY",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "NRML",
        "quantity": 500,
        "disclosed_quantity": 0,
        "price": 0,
        "trigger_price": 0,
        "average_price": 148.9375,
        "filled_quantity": 500,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": null,
        "guid": "19Xpvmrupzvvkpj"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200146969",
        "exchange_order_id": "1500000002235946",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T03:48:42.000Z",
        "exchange_update_timestamp": "2024-06-07 09:18:42",
        "exchange_timestamp": "2024-06-07T03:48:42.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NFO",
        "tradingsymbol": "BANKNIFTY2461249600CE",
        "instrument_token": 9420802,
        "order_type": "MARKET",
        "transaction_type": "BUY",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "NRML",
        "quantity": 180,
        "disclosed_quantity": 0,
        "price": 0,
        "trigger_price": 0,
        "average_price": 401.675,
        "filled_quantity": 180,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": null,
        "guid": "19Xnhwnajswzcwe"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200172761",
        "exchange_order_id": "1000000002529750",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T03:50:02.000Z",
        "exchange_update_timestamp": "2024-06-07 09:20:02",
        "exchange_timestamp": "2024-06-07T03:50:02.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NFO",
        "tradingsymbol": "NIFTY2461322850CE",
        "instrument_token": 11244802,
        "order_type": "MARKET",
        "transaction_type": "SELL",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "MIS",
        "quantity": 950,
        "disclosed_quantity": 0,
        "price": 0,
        "trigger_price": 0,
        "average_price": 222.69342104999998,
        "filled_quantity": 950,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": "DxIg1b4E",
        "tags": [
            "DxIg1b4E"
        ],
        "guid": "33060XS3fMEJ9QG1pg"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200172764",
        "exchange_order_id": "1700000002902008",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T03:50:02.000Z",
        "exchange_update_timestamp": "2024-06-07 09:20:02",
        "exchange_timestamp": "2024-06-07T03:50:02.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NFO",
        "tradingsymbol": "BANKNIFTY2461249200PE",
        "instrument_token": 9407234,
        "order_type": "MARKET",
        "transaction_type": "SELL",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "MIS",
        "quantity": 225,
        "disclosed_quantity": 0,
        "price": 0,
        "trigger_price": 0,
        "average_price": 558.37666667,
        "filled_quantity": 225,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": "83tHET70",
        "tags": [
            "83tHET70"
        ],
        "guid": "33060X6XaLA79gVbkc"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200172767",
        "exchange_order_id": "2000000002418932",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T03:50:02.000Z",
        "exchange_update_timestamp": "2024-06-07 09:20:02",
        "exchange_timestamp": "2024-06-07T03:50:02.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NFO",
        "tradingsymbol": "NIFTY2461322850PE",
        "instrument_token": 11245058,
        "order_type": "MARKET",
        "transaction_type": "SELL",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "MIS",
        "quantity": 950,
        "disclosed_quantity": 0,
        "price": 0,
        "trigger_price": 0,
        "average_price": 222.24736842,
        "filled_quantity": 950,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": "DxIg1b4E",
        "tags": [
            "DxIg1b4E"
        ],
        "guid": "33060XMQjPuayo0Pdr"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200172775",
        "exchange_order_id": "1500000003001667",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T03:50:02.000Z",
        "exchange_update_timestamp": "2024-06-07 09:20:02",
        "exchange_timestamp": "2024-06-07T03:50:02.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NFO",
        "tradingsymbol": "BANKNIFTY2461249200CE",
        "instrument_token": 9403394,
        "order_type": "MARKET",
        "transaction_type": "SELL",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "MIS",
        "quantity": 225,
        "disclosed_quantity": 0,
        "price": 0,
        "trigger_price": 0,
        "average_price": 577.11,
        "filled_quantity": 225,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": "83tHET70",
        "tags": [
            "83tHET70"
        ],
        "guid": "33060XB2EtKiQq1p9y"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200211862",
        "exchange_order_id": "1000000004119096",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T03:51:49.000Z",
        "exchange_update_timestamp": "2024-06-07 09:21:49",
        "exchange_timestamp": "2024-06-07T03:51:49.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NFO",
        "tradingsymbol": "NIFTY2461322850CE",
        "instrument_token": 11244802,
        "order_type": "MARKET",
        "transaction_type": "BUY",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "MIS",
        "quantity": 950,
        "disclosed_quantity": 0,
        "price": 0,
        "trigger_price": 0,
        "average_price": 250.37631579,
        "filled_quantity": 950,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": "DxIg1b4E",
        "tags": [
            "DxIg1b4E"
        ],
        "guid": "33060X53rHZPeFlpMQ"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200211923",
        "exchange_order_id": "2000000003889464",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T03:51:49.000Z",
        "exchange_update_timestamp": "2024-06-07 09:21:49",
        "exchange_timestamp": "2024-06-07T03:51:49.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NFO",
        "tradingsymbol": "NIFTY2461322850PE",
        "instrument_token": 11245058,
        "order_type": "MARKET",
        "transaction_type": "BUY",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "MIS",
        "quantity": 950,
        "disclosed_quantity": 0,
        "price": 0,
        "trigger_price": 0,
        "average_price": 211.63026316,
        "filled_quantity": 950,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": "DxIg1b4E",
        "tags": [
            "DxIg1b4E"
        ],
        "guid": "33060XK4udYx34z5H0"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200596324",
        "exchange_order_id": "1000000008174411",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T04:19:11.000Z",
        "exchange_update_timestamp": "2024-06-07 09:49:11",
        "exchange_timestamp": "2024-06-07T04:19:11.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NSE",
        "tradingsymbol": "BSE",
        "instrument_token": 5013761,
        "order_type": "LIMIT",
        "transaction_type": "BUY",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "CNC",
        "quantity": 11,
        "disclosed_quantity": 0,
        "price": 2687.5,
        "trigger_price": 0,
        "average_price": 2685.7,
        "filled_quantity": 11,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": null,
        "guid": "01XlixieuUM2YS6"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200596325",
        "exchange_order_id": "1300000008308367",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T04:21:12.000Z",
        "exchange_update_timestamp": "2024-06-07 09:51:12",
        "exchange_timestamp": "2024-06-07T04:19:11.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NSE",
        "tradingsymbol": "SOBHA",
        "instrument_token": 3539457,
        "order_type": "LIMIT",
        "transaction_type": "BUY",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "CNC",
        "quantity": 100,
        "disclosed_quantity": 0,
        "price": 2085,
        "trigger_price": 0,
        "average_price": 2085,
        "filled_quantity": 100,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": null,
        "guid": "01XgjfRYrKDjvHT"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200629801",
        "exchange_order_id": "1000000008734279",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T04:22:44.000Z",
        "exchange_update_timestamp": "2024-06-07 09:52:44",
        "exchange_timestamp": "2024-06-07T04:22:44.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NSE",
        "tradingsymbol": "BHARTIARTL",
        "instrument_token": 2714625,
        "order_type": "LIMIT",
        "transaction_type": "BUY",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "CNC",
        "quantity": 17,
        "disclosed_quantity": 0,
        "price": 1374,
        "trigger_price": 0,
        "average_price": 1371.55,
        "filled_quantity": 17,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": null,
        "guid": "01XtjTgQtRpBSDe"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200629804",
        "exchange_order_id": "1100000010343104",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T04:22:44.000Z",
        "exchange_update_timestamp": "2024-06-07 09:52:44",
        "exchange_timestamp": "2024-06-07T04:22:44.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NSE",
        "tradingsymbol": "GRASIM",
        "instrument_token": 315393,
        "order_type": "LIMIT",
        "transaction_type": "BUY",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "CNC",
        "quantity": 5,
        "disclosed_quantity": 0,
        "price": 2348,
        "trigger_price": 0,
        "average_price": 2347.9,
        "filled_quantity": 5,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": null,
        "guid": "01Xb2q0j4pYKDXb"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200629806",
        "exchange_order_id": "1200000009917777",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T04:22:44.000Z",
        "exchange_update_timestamp": "2024-06-07 09:52:44",
        "exchange_timestamp": "2024-06-07T04:22:44.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NSE",
        "tradingsymbol": "MARUTI",
        "instrument_token": 2815745,
        "order_type": "LIMIT",
        "transaction_type": "BUY",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "CNC",
        "quantity": 1,
        "disclosed_quantity": 0,
        "price": 12707,
        "trigger_price": 0,
        "average_price": 12676.35,
        "filled_quantity": 1,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": null,
        "guid": "01XWOiIeJtpDDA4"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200629808",
        "exchange_order_id": "1300000008870579",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T04:22:44.000Z",
        "exchange_update_timestamp": "2024-06-07 09:52:44",
        "exchange_timestamp": "2024-06-07T04:22:44.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NSE",
        "tradingsymbol": "SUNPHARMA",
        "instrument_token": 857857,
        "order_type": "LIMIT",
        "transaction_type": "BUY",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "CNC",
        "quantity": 11,
        "disclosed_quantity": 0,
        "price": 1480.5,
        "trigger_price": 0,
        "average_price": 1475.9772727299999,
        "filled_quantity": 11,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": null,
        "guid": "01X2cin3cJsqo2g"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200629809",
        "exchange_order_id": "1300000008870611",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T04:22:44.000Z",
        "exchange_update_timestamp": "2024-06-07 09:52:44",
        "exchange_timestamp": "2024-06-07T04:22:44.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NSE",
        "tradingsymbol": "TORNTPHARM",
        "instrument_token": 900609,
        "order_type": "LIMIT",
        "transaction_type": "BUY",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "CNC",
        "quantity": 5,
        "disclosed_quantity": 0,
        "price": 2773,
        "trigger_price": 0,
        "average_price": 2763.5,
        "filled_quantity": 5,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": null,
        "guid": "01XvuSJ5fDEJBWp"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200629810",
        "exchange_order_id": "1000000008734306",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T04:22:44.000Z",
        "exchange_update_timestamp": "2024-06-07 09:52:44",
        "exchange_timestamp": "2024-06-07T04:22:44.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NSE",
        "tradingsymbol": "CPSEETF",
        "instrument_token": 595969,
        "order_type": "LIMIT",
        "transaction_type": "BUY",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "CNC",
        "quantity": 285,
        "disclosed_quantity": 0,
        "price": 88.5,
        "trigger_price": 0,
        "average_price": 88.09,
        "filled_quantity": 285,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": null,
        "guid": "01XqmxewT7svv1W"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200629812",
        "exchange_order_id": "1300000008870628",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T04:22:44.000Z",
        "exchange_update_timestamp": "2024-06-07 09:52:44",
        "exchange_timestamp": "2024-06-07T04:22:44.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NSE",
        "tradingsymbol": "RELIANCE",
        "instrument_token": 738561,
        "order_type": "LIMIT",
        "transaction_type": "BUY",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "CNC",
        "quantity": 5,
        "disclosed_quantity": 0,
        "price": 2882,
        "trigger_price": 0,
        "average_price": 2877.1,
        "filled_quantity": 5,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": null,
        "guid": "01XmbpRIJUG3X8O"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200629807",
        "exchange_order_id": "1200000009917776",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T04:22:45.000Z",
        "exchange_update_timestamp": "2024-06-07 09:52:45",
        "exchange_timestamp": "2024-06-07T04:22:44.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NSE",
        "tradingsymbol": "LICI",
        "instrument_token": 2426881,
        "order_type": "LIMIT",
        "transaction_type": "BUY",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "CNC",
        "quantity": 17,
        "disclosed_quantity": 0,
        "price": 993,
        "trigger_price": 0,
        "average_price": 993,
        "filled_quantity": 17,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": null,
        "guid": "01XtxnUZF2Cbb7f"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200629811",
        "exchange_order_id": "1100000010343119",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T04:23:21.000Z",
        "exchange_update_timestamp": "2024-06-07 09:53:21",
        "exchange_timestamp": "2024-06-07T04:22:44.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NSE",
        "tradingsymbol": "DRREDDY",
        "instrument_token": 225537,
        "order_type": "LIMIT",
        "transaction_type": "BUY",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "CNC",
        "quantity": 2,
        "disclosed_quantity": 0,
        "price": 5949,
        "trigger_price": 0,
        "average_price": 5949,
        "filled_quantity": 2,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": null,
        "guid": "01XKkZmRJdInvEO"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200629802",
        "exchange_order_id": "1000000008734283",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T04:23:36.000Z",
        "exchange_update_timestamp": "2024-06-07 09:53:36",
        "exchange_timestamp": "2024-06-07T04:22:44.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NSE",
        "tradingsymbol": "COLPAL",
        "instrument_token": 3876097,
        "order_type": "LIMIT",
        "transaction_type": "BUY",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "CNC",
        "quantity": 6,
        "disclosed_quantity": 0,
        "price": 2937,
        "trigger_price": 0,
        "average_price": 2937,
        "filled_quantity": 6,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": null,
        "guid": "01XANN84Wo1kUgf"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200629805",
        "exchange_order_id": "1100000010343105",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T04:23:36.000Z",
        "exchange_update_timestamp": "2024-06-07 09:53:36",
        "exchange_timestamp": "2024-06-07T04:22:44.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NSE",
        "tradingsymbol": "HDFCAMC",
        "instrument_token": 1086465,
        "order_type": "LIMIT",
        "transaction_type": "BUY",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "CNC",
        "quantity": 3,
        "disclosed_quantity": 0,
        "price": 3745.5,
        "trigger_price": 0,
        "average_price": 3745.5,
        "filled_quantity": 3,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": null,
        "guid": "01XFOsNss3f4iLC"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200596323",
        "exchange_order_id": "1200000009295029",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T04:30:11.000Z",
        "exchange_update_timestamp": "2024-06-07 10:00:11",
        "exchange_timestamp": "2024-06-07T04:19:11.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NSE",
        "tradingsymbol": "NTPC",
        "instrument_token": 2977281,
        "order_type": "LIMIT",
        "transaction_type": "SELL",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "CNC",
        "quantity": 591,
        "disclosed_quantity": 0,
        "price": 351,
        "trigger_price": 0,
        "average_price": 351,
        "filled_quantity": 591,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": null,
        "guid": "01XKQrwKRBWeQC8"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200749794",
        "exchange_order_id": "1300000010524703",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T04:33:07.000Z",
        "exchange_update_timestamp": "2024-06-07 10:03:07",
        "exchange_timestamp": "2024-06-07T04:33:07.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NSE",
        "tradingsymbol": "SANOFI",
        "instrument_token": 369153,
        "order_type": "LIMIT",
        "transaction_type": "BUY",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "CNC",
        "quantity": 1,
        "disclosed_quantity": 0,
        "price": 9197.5,
        "trigger_price": 0,
        "average_price": 9197.5,
        "filled_quantity": 1,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": null,
        "guid": "01XlP8iZzti4anl"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200754750",
        "exchange_order_id": "1300000010585273",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T04:33:34.000Z",
        "exchange_update_timestamp": "2024-06-07 10:03:34",
        "exchange_timestamp": "2024-06-07T04:33:33.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NSE",
        "tradingsymbol": "ULTRACEMCO",
        "instrument_token": 2952193,
        "order_type": "LIMIT",
        "transaction_type": "BUY",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "CNC",
        "quantity": 1,
        "disclosed_quantity": 0,
        "price": 10120.5,
        "trigger_price": 0,
        "average_price": 10120.5,
        "filled_quantity": 1,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": null,
        "guid": "01XIje1JXZbH5Ij"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607200744554",
        "exchange_order_id": "1200000011676947",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T04:35:54.000Z",
        "exchange_update_timestamp": "2024-06-07 10:05:54",
        "exchange_timestamp": "2024-06-07T04:32:39.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NSE",
        "tradingsymbol": "ONGC",
        "instrument_token": 633601,
        "order_type": "LIMIT",
        "transaction_type": "BUY",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "CNC",
        "quantity": 63,
        "disclosed_quantity": 0,
        "price": 256.5,
        "trigger_price": 0,
        "average_price": 256.5,
        "filled_quantity": 63,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": null,
        "guid": "01X8TU4g14CA7wq"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607201010540",
        "exchange_order_id": "1300000014300525",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T04:59:21.000Z",
        "exchange_update_timestamp": "2024-06-07 10:29:21",
        "exchange_timestamp": "2024-06-07T04:59:21.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NSE",
        "tradingsymbol": "SAMHI",
        "instrument_token": 4765185,
        "order_type": "LIMIT",
        "transaction_type": "BUY",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "CNC",
        "quantity": 44,
        "disclosed_quantity": 0,
        "price": 183.5,
        "trigger_price": 0,
        "average_price": 183.4,
        "filled_quantity": 44,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": null,
        "guid": "01XBPFX0MQq3fc7"
    },
    {
        "placed_by": "ZZ0829",
        "order_id": "240607201010538",
        "exchange_order_id": "1200000015956151",
        "parent_order_id": null,
        "status": "COMPLETE",
        "status_message": null,
        "status_message_raw": null,
        "order_timestamp": "2024-06-07T05:00:06.000Z",
        "exchange_update_timestamp": "2024-06-07 10:30:06",
        "exchange_timestamp": "2024-06-07T04:59:21.000Z",
        "variety": "regular",
        "modified": false,
        "exchange": "NSE",
        "tradingsymbol": "POONAWALLA",
        "instrument_token": 2919169,
        "order_type": "LIMIT",
        "transaction_type": "BUY",
        "validity": "DAY",
        "validity_ttl": 0,
        "product": "CNC",
        "quantity": 23,
        "disclosed_quantity": 0,
        "price": 455.5,
        "trigger_price": 0,
        "average_price": 455.5,
        "filled_quantity": 23,
        "pending_quantity": 0,
        "cancelled_quantity": 0,
        "market_protection": 0,
        "meta": {},
        "tag": null,
        "guid": "01X2xCdeV12JEso"
    }
]';

 create_trades(l_clob);
 END;
 /
 */