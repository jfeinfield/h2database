-- Copyright 2004-2020 H2 Group. Multiple-Licensed under the MPL 2.0,
-- and the EPL 1.0 (https://h2database.com/html/license.html).
-- Initial Developer: H2 Group
--

CREATE SCHEMA S1;
> ok

CREATE SCHEMA S2;
> ok

CREATE DOMAIN S1.D1 AS INT DEFAULT 1;
> ok

CREATE DOMAIN S2.D2 AS TIMESTAMP WITH TIME ZONE ON UPDATE CURRENT_TIMESTAMP;
> ok

CREATE TABLE TEST(C1 S1.D1, C2 S2.D2);
> ok

SELECT COLUMN_NAME, DOMAIN_CATALOG, DOMAIN_SCHEMA, DOMAIN_NAME, COLUMN_DEFAULT, COLUMN_TYPE, COLUMN_ON_UPDATE
    FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TEST' ORDER BY ORDINAL_POSITION;
> COLUMN_NAME DOMAIN_CATALOG DOMAIN_SCHEMA DOMAIN_NAME COLUMN_DEFAULT COLUMN_TYPE                           COLUMN_ON_UPDATE
> ----------- -------------- ------------- ----------- -------------- ------------------------------------- -----------------
> C1          SCRIPT         S1            D1          1              "S1"."D1" DEFAULT 1                   null
> C2          SCRIPT         S2            D2          null           "S2"."D2" ON UPDATE CURRENT_TIMESTAMP CURRENT_TIMESTAMP
> rows (ordered): 2

SELECT DOMAIN_CATALOG, DOMAIN_SCHEMA, DOMAIN_NAME, DOMAIN_DEFAULT, DOMAIN_ON_UPDATE, TYPE_NAME FROM INFORMATION_SCHEMA.DOMAINS;
> DOMAIN_CATALOG DOMAIN_SCHEMA DOMAIN_NAME DOMAIN_DEFAULT DOMAIN_ON_UPDATE  TYPE_NAME
> -------------- ------------- ----------- -------------- ----------------- ------------------------
> SCRIPT         S1            D1          1              null              INTEGER
> SCRIPT         S2            D2          null           CURRENT_TIMESTAMP TIMESTAMP WITH TIME ZONE
> rows: 2

DROP TABLE TEST;
> ok

DROP DOMAIN S1.D1;
> ok

DROP SCHEMA S1 RESTRICT;
> ok

DROP SCHEMA S2 RESTRICT;
> exception CANNOT_DROP_2

DROP SCHEMA S2 CASCADE;
> ok

CREATE DOMAIN D INT;
> ok

CREATE MEMORY TABLE TEST(C D);
> ok

ALTER DOMAIN D ADD CHECK (VALUE <> 0);
> ok

ALTER DOMAIN D ADD CONSTRAINT D1 CHECK (VALUE > 0);
> ok

ALTER DOMAIN D ADD CONSTRAINT D1 CHECK (VALUE > 0);
> exception CONSTRAINT_ALREADY_EXISTS_1

ALTER DOMAIN D ADD CONSTRAINT IF NOT EXISTS D1 CHECK (VALUE > 0);
> ok

ALTER DOMAIN X ADD CHECK (VALUE > 0);
> exception DOMAIN_NOT_FOUND_1

ALTER DOMAIN IF EXISTS X ADD CHECK (VALUE > 0);
> ok

INSERT INTO TEST VALUES -1;
> exception CHECK_CONSTRAINT_VIOLATED_1

ALTER DOMAIN D DROP CONSTRAINT D1;
> ok

ALTER DOMAIN D DROP CONSTRAINT D1;
> exception CONSTRAINT_NOT_FOUND_1

ALTER DOMAIN D DROP CONSTRAINT IF EXISTS D1;
> ok

ALTER DOMAIN IF EXISTS X DROP CONSTRAINT D1;
> ok

ALTER DOMAIN X DROP CONSTRAINT IF EXISTS D1;
> exception DOMAIN_NOT_FOUND_1

SCRIPT NOPASSWORDS NOSETTINGS;
> SCRIPT
> -------------------------------------------------------------------------------------------
> -- 0 +/- SELECT COUNT(*) FROM PUBLIC.TEST;
> ALTER DOMAIN "PUBLIC"."D" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_4" CHECK(VALUE <> 0) NOCHECK;
> CREATE DOMAIN "PUBLIC"."D" AS INT;
> CREATE MEMORY TABLE "PUBLIC"."TEST"( "C" "PUBLIC"."D" );
> CREATE USER IF NOT EXISTS "SA" PASSWORD '' ADMIN;
> rows: 5

SELECT CONSTRAINT_NAME, DOMAIN_NAME, SQL FROM INFORMATION_SCHEMA.DOMAIN_CONSTRAINTS;
> CONSTRAINT_NAME DOMAIN_NAME SQL
> --------------- ----------- ------------------------------------------------------------------------------------------
> CONSTRAINT_4    D           ALTER DOMAIN "PUBLIC"."D" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_4" CHECK(VALUE <> 0) NOCHECK
> rows: 1

TABLE INFORMATION_SCHEMA.CHECK_CONSTRAINTS;
> CONSTRAINT_CATALOG CONSTRAINT_SCHEMA CONSTRAINT_NAME CHECK_CLAUSE
> ------------------ ----------------- --------------- ------------
> SCRIPT             PUBLIC            CONSTRAINT_4    VALUE <> 0
> rows: 1

SELECT COUNT(*) FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE;
>> 0

INSERT INTO TEST VALUES -1;
> update count: 1

INSERT INTO TEST VALUES 0;
> exception CHECK_CONSTRAINT_VIOLATED_1

DROP DOMAIN D RESTRICT;
> exception CANNOT_DROP_2

DROP DOMAIN D CASCADE;
> ok

SCRIPT NOPASSWORDS NOSETTINGS;
> SCRIPT
> -------------------------------------------------------------------------------------------
> -- 1 +/- SELECT COUNT(*) FROM PUBLIC.TEST;
> ALTER TABLE "PUBLIC"."TEST" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_2" CHECK("C" <> 0) NOCHECK;
> CREATE MEMORY TABLE "PUBLIC"."TEST"( "C" INT );
> CREATE USER IF NOT EXISTS "SA" PASSWORD '' ADMIN;
> INSERT INTO "PUBLIC"."TEST" VALUES (-1);
> rows: 5

SELECT CONSTRAINT_NAME, CONSTRAINT_TYPE, TABLE_NAME, SQL FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS;
> CONSTRAINT_NAME CONSTRAINT_TYPE TABLE_NAME SQL
> --------------- --------------- ---------- ------------------------------------------------------------------------------------------
> CONSTRAINT_2    CHECK           TEST       ALTER TABLE "PUBLIC"."TEST" ADD CONSTRAINT "PUBLIC"."CONSTRAINT_2" CHECK("C" <> 0) NOCHECK
> rows: 1

TABLE INFORMATION_SCHEMA.CHECK_CONSTRAINTS;
> CONSTRAINT_CATALOG CONSTRAINT_SCHEMA CONSTRAINT_NAME CHECK_CLAUSE
> ------------------ ----------------- --------------- ------------
> SCRIPT             PUBLIC            CONSTRAINT_2    "C" <> 0
> rows: 1

TABLE INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE;
> TABLE_CATALOG TABLE_SCHEMA TABLE_NAME COLUMN_NAME CONSTRAINT_CATALOG CONSTRAINT_SCHEMA CONSTRAINT_NAME
> ------------- ------------ ---------- ----------- ------------------ ----------------- ---------------
> SCRIPT        PUBLIC       TEST       C           SCRIPT             PUBLIC            CONSTRAINT_2
> rows: 1

DROP TABLE TEST;
> ok

CREATE DOMAIN D1 AS INT DEFAULT 1 CHECK (VALUE >= 1);
> ok

CREATE DOMAIN D2 AS D1 DEFAULT 2;
> ok

CREATE DOMAIN D3 AS D1 CHECK (VALUE >= 3);
> ok

CREATE DOMAIN D4 AS D1 DEFAULT 4 CHECK (VALUE >= 4);
> ok

SELECT DOMAIN_CATALOG, DOMAIN_SCHEMA, DOMAIN_NAME, DOMAIN_DEFAULT, DOMAIN_ON_UPDATE, DATA_TYPE, PRECISION, SCALE, TYPE_NAME,
    PARENT_DOMAIN_CATALOG, PARENT_DOMAIN_SCHEMA, PARENT_DOMAIN_NAME FROM INFORMATION_SCHEMA.DOMAINS WHERE DOMAIN_SCHEMA = 'PUBLIC';
> DOMAIN_CATALOG DOMAIN_SCHEMA DOMAIN_NAME DOMAIN_DEFAULT DOMAIN_ON_UPDATE DATA_TYPE PRECISION SCALE TYPE_NAME PARENT_DOMAIN_CATALOG PARENT_DOMAIN_SCHEMA PARENT_DOMAIN_NAME
> -------------- ------------- ----------- -------------- ---------------- --------- --------- ----- --------- --------------------- -------------------- ------------------
> SCRIPT         PUBLIC        D1          1              null             4         10        0     INTEGER   null                  null                 null
> SCRIPT         PUBLIC        D2          2              null             4         10        0     INTEGER   SCRIPT                PUBLIC               D1
> SCRIPT         PUBLIC        D3          1              null             4         10        0     INTEGER   SCRIPT                PUBLIC               D1
> SCRIPT         PUBLIC        D4          4              null             4         10        0     INTEGER   SCRIPT                PUBLIC               D1
> rows: 4

SELECT DOMAIN_NAME, CHECK_CLAUSE FROM INFORMATION_SCHEMA.DOMAIN_CONSTRAINTS D JOIN INFORMATION_SCHEMA.CHECK_CONSTRAINTS C
    ON D.CONSTRAINT_CATALOG = C.CONSTRAINT_CATALOG AND D.CONSTRAINT_SCHEMA = C.CONSTRAINT_SCHEMA AND D.CONSTRAINT_NAME = C.CONSTRAINT_NAME
    WHERE C.CONSTRAINT_SCHEMA = 'PUBLIC';
> DOMAIN_NAME CHECK_CLAUSE
> ----------- ------------
> D1          VALUE >= 1
> D3          VALUE >= 3
> D4          VALUE >= 4
> rows: 3

VALUES CAST(0 AS D2);
> exception CHECK_CONSTRAINT_VIOLATED_1

DROP DOMAIN D1;
> exception CANNOT_DROP_2

DROP DOMAIN D1 CASCADE;
> ok

SELECT DOMAIN_CATALOG, DOMAIN_SCHEMA, DOMAIN_NAME, DOMAIN_DEFAULT, DOMAIN_ON_UPDATE, DATA_TYPE, PRECISION, SCALE, TYPE_NAME,
    PARENT_DOMAIN_CATALOG, PARENT_DOMAIN_SCHEMA, PARENT_DOMAIN_NAME FROM INFORMATION_SCHEMA.DOMAINS WHERE DOMAIN_SCHEMA = 'PUBLIC';
> DOMAIN_CATALOG DOMAIN_SCHEMA DOMAIN_NAME DOMAIN_DEFAULT DOMAIN_ON_UPDATE DATA_TYPE PRECISION SCALE TYPE_NAME PARENT_DOMAIN_CATALOG PARENT_DOMAIN_SCHEMA PARENT_DOMAIN_NAME
> -------------- ------------- ----------- -------------- ---------------- --------- --------- ----- --------- --------------------- -------------------- ------------------
> SCRIPT         PUBLIC        D2          2              null             4         10        0     INTEGER   null                  null                 null
> SCRIPT         PUBLIC        D3          1              null             4         10        0     INTEGER   null                  null                 null
> SCRIPT         PUBLIC        D4          4              null             4         10        0     INTEGER   null                  null                 null
> rows: 3

SELECT DOMAIN_NAME, CHECK_CLAUSE FROM INFORMATION_SCHEMA.DOMAIN_CONSTRAINTS D JOIN INFORMATION_SCHEMA.CHECK_CONSTRAINTS C
    ON D.CONSTRAINT_CATALOG = C.CONSTRAINT_CATALOG AND D.CONSTRAINT_SCHEMA = C.CONSTRAINT_SCHEMA AND D.CONSTRAINT_NAME = C.CONSTRAINT_NAME
    WHERE C.CONSTRAINT_SCHEMA = 'PUBLIC';
> DOMAIN_NAME CHECK_CLAUSE
> ----------- ------------
> D2          VALUE >= 1
> D3          VALUE >= 1
> D3          VALUE >= 3
> D4          VALUE >= 1
> D4          VALUE >= 4
> rows: 5

DROP DOMAIN D2;
> ok

DROP DOMAIN D3;
> ok

DROP DOMAIN D4;
> ok

CREATE DOMAIN D1 INT;
> ok

CREATE DOMAIN D2 INT;
> ok

DROP DOMAIN D1;
> ok

CREATE DOMAIN D3 D2;
> ok

@reconnect

DROP DOMAIN D3;
> ok

DROP DOMAIN D2;
> ok