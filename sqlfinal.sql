-- ======================================================================
-- Type definitions
-- ======================================================================
DROP TABLE A_customers CASCADE CONSTRAINTS;
DROP TYPE cust_address_typ;
CREATE TYPE cust_address_typ
AS OBJECT
(
    street_address VARCHAR2(40),
    postal_code    VARCHAR2(10),
    city           VARCHAR2(30),
    state_province VARCHAR2(10),
    country_id     CHAR(2)
);
/

REM ===========================================================================
REM Create
phone_list_typ varray to be varray column in A_customers table.
REM ===========================================================================

DROP TYPE phone_list_typ;
CREATE TYPE phone_list_typ
AS VARRAY(5) OF VARCHAR2(25);
/

REM ===========================================================================
REM Create
A_customers table.
REM The cust_geo_location column will become MDSYS.SDO_GEOMETRY (spatial)
REM datatype when appropriate scripts and data are available.
REM ===========================================================================


CREATE TABLE A_customers
(
    customer_id     NUMBER(6),
    cust_first_name VARCHAR2(20)
        CONSTRAINT cust_fname_nn NOT NULL,
    cust_last_name  VARCHAR2(20)
        CONSTRAINT cust_lname_nn NOT NULL,
    cust_address    cust_address_typ,
    phone_numbers   varchar2(30),
    nls_language    VARCHAR2(3),
    nls_territory   VARCHAR2(30),
    credit_limit    NUMBER(9, 2),
    cust_email      VARCHAR2(30),
    account_mgr_id  NUMBER(6),
    CONSTRAINT customer_credit_limit_max
        CHECK (credit_limit <= 5000),
    CONSTRAINT customer_id_min
        CHECK (customer_id > 0)
);

CREATE UNIQUE INDEX A_customers_pk
    ON A_customers (customer_id);

REM Both table and indexes are analyzed using the oe_analz.sql script.

ALTER TABLE A_customers
ADD ( CONSTRAINT A_customers_pk
      PRIMARY KEY (customer_id)
    );

REM ===========================================================================
REM Create
A_warehouses table;
REM  includes spatial data column wh_geo_location and
REM  XML type warehouse_spec (was bug b41)
REM ===========================================================================

DROP TABLE A_warehouses CASCADE CONSTRAINTS;
CREATE TABLE A_warehouses
(
    warehouse_id   NUMBER(3),
    warehouse_name VARCHAR2(35),
    location_id    NUMBER(4)
);

CREATE UNIQUE INDEX A_warehouses_pk
    ON A_warehouses (warehouse_id);

ALTER TABLE A_warehouses
    ADD (CONSTRAINT A_warehouses_pk PRIMARY KEY (warehouse_id)
        );

REM ===========================================================================
REM
Create table A_order_items.
    REM ===========================================================================

DROP TABLE A_order_items CASCADE CONSTRAINTS;
CREATE TABLE A_order_items
(
    order_id     NUMBER(12),
    line_item_id NUMBER(3) NOT NULL,
    product_id   NUMBER(6) NOT NULL,
    unit_price   NUMBER(8, 2),
    quantity     NUMBER(8)
);

CREATE UNIQUE INDEX A_order_items_pk
    ON A_order_items (order_id, line_item_id);

CREATE UNIQUE INDEX A_order_items_uk
    ON A_order_items (order_id, product_id);

ALTER TABLE A_order_items
    ADD (CONSTRAINT A_order_items_pk PRIMARY KEY (order_id, line_item_id)
        );

CREATE OR REPLACE TRIGGER insert_ord_line
    BEFORE INSERT
    ON A_order_items
    FOR EACH ROW
DECLARE
    new_line number;
BEGIN
    SELECT (NVL(MAX(line_item_id), 0) + 1)
    INTO new_line
    FROM A_order_items
    WHERE order_id = :new.order_id;
    :new.line_item_id := new_line;
END;
/

REM ===========================================================================
REM
Create table A_orders, which includes a TIMESTAMP column and a check
REM constraint.
REM ===========================================================================

DROP TABLE A_orders CASCADE CONSTRAINTS;
CREATE TABLE A_orders
(
    order_id     NUMBER(12),
    order_date   DATE
        CONSTRAINT order_date_nn NOT NULL,
    order_mode   VARCHAR2(8),
    customer_id  NUMBER(6)
        CONSTRAINT order_customer_id_nn NOT NULL,
    order_status NUMBER(2),
    order_total  NUMBER(8, 2),
    sales_rep_id NUMBER(6),
    promotion_id NUMBER(6),
    CONSTRAINT order_mode_lov
        CHECK (order_mode in ('direct', 'online')),
    constraint order_total_min
        check (order_total >= 0)
);

CREATE UNIQUE INDEX order_pk
    ON A_orders (order_id);

ALTER TABLE A_orders
    ADD (CONSTRAINT order_pk
        PRIMARY KEY (order_id)
        );
REM ===========================================================================
REM Create
A_inventories table, which contains a concatenated primary key.
REM ===========================================================================

DROP TABLE A_inventories CASCADE CONSTRAINTS;
CREATE TABLE A_inventories
(
    product_id       NUMBER(6),
    warehouse_id     NUMBER(3)
        CONSTRAINT inventory_warehouse_id_nn NOT NULL,
    quantity_on_hand NUMBER(8)
        CONSTRAINT inventory_qoh_nn NOT NULL,
    CONSTRAINT inventory_pk PRIMARY KEY (product_id, warehouse_id)
);

REM ===========================================================================
REM
Create table A_product_information, which contains an INTERVAL datatype and
REM a CHECK ... IN constraint.
REM ===========================================================================

DROP TABLE A_product_information CASCADE CONSTRAINTS;
CREATE TABLE A_product_information
(
    product_id          NUMBER(6),
    product_name        VARCHAR2(50),
    product_description VARCHAR2(2000),
    category_id         NUMBER(2),
    weight_class        NUMBER(1),
    warranty_period     NUMBER(5),
    supplier_id         NUMBER(6),
    product_status      VARCHAR2(20),
    list_price          NUMBER(8, 2),
    min_price           NUMBER(8, 2),
    catalog_url         VARCHAR2(50),
    CONSTRAINT product_status_lov
        CHECK (product_status in ('orderable', 'planned', 'under development', 'obsolete')
            )
);

ALTER TABLE A_product_information
    ADD (CONSTRAINT A_product_information_pk PRIMARY KEY (product_id)
        );


ALTER TABLE A_orders
    ADD (CONSTRAINT A_orders_customer_id_fk
        FOREIGN KEY (customer_id)
            REFERENCES A_customers (customer_id)
                ON DELETE SET NULL
        );


ALTER TABLE A_inventories
    ADD (CONSTRAINT A_inventories_A_warehouses_fk
        FOREIGN KEY (warehouse_id)
            REFERENCES A_warehouses (warehouse_id)
                ENABLE NOVALIDATE
        );

ALTER TABLE A_inventories
    ADD (CONSTRAINT A_inventories_product_id_fk
        FOREIGN KEY (product_id)
            REFERENCES A_product_information (product_id)
        );

ALTER TABLE A_order_items
    ADD (CONSTRAINT A_order_items_order_id_fk
        FOREIGN KEY (order_id)
            REFERENCES A_orders (order_id)
                ON DELETE CASCADE
                enable novalidate
        );

ALTER TABLE A_order_items
    ADD (CONSTRAINT A_order_items_product_id_fk
        FOREIGN KEY (product_id)
            REFERENCES A_product_information (product_id)
        );


REM ===========================================================================
REM Create
cross-schema synonyms
REM ===========================================================================

-- CREATE SYNONYM countries FOR countries;

-- CREATE SYNONYM locations FOR locations;

-- CREATE SYNONYM departments FOR departments;

-- CREATE SYNONYM jobs FOR jobs;

-- CREATE SYNONYM employees FOR employees;

-- CREATE SYNONYM job_history FOR job_history;

-- CREATE SYNONYM regions FOR regions;

REM ===========================================================================
REM Create
sequences
REM ===========================================================================

CREATE SEQUENCE A_orders_seq
    START WITH 1000
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

CREATE SEQUENCE A_customers_seq
    START WITH 982
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

REM ===========================================================================
REM Need
commit for PO
REM ===========================================================================

COMMIT;

rem
rem Header: oe8_p_cus.sql 09-jan-01
rem
rem Copyright (c) 2001 Oracle Corporation.  All rights reserved.
rem
rem Owner  : ahunold
rem
rem NAME
rem   oe8_p_cus.sql - populate OE Common Schema
rem
rem DESCRIPTON
rem   Table A_customers
rem
rem MODIFIED   (MM/DD/YY)
rem   ahunold   10/
03/
01 - 8i

INSERT INTO A_customers
VALUES (101, 'Constantin', 'Welles', cust_address_typ
    ('514 W Superior St', '46901', 'Kokomo', 'IN', 'US'),
        '+1 317 123 4104', 'us', 'AMERICA', '100', 'Constantin.Welles@ANHINGA.COM',
        149);
INSERT INTO A_customers
VALUES (102, 'Harrison', 'Pacino', cust_address_typ
    ('2515 Bloyd Ave', '46218', 'Indianapolis', 'IN', 'US'),
        '+1 317 123 4111', 'us', 'AMERICA', '100', 'Harrison.Pacino@ANI.COM',
        149);
INSERT INTO A_customers
VALUES (103, 'Manisha', 'Taylor', cust_address_typ
    ('8768 N State Rd 37', '47404', 'Bloomington', 'IN', 'US'),
        '+1 812 123 4115', 'us', 'AMERICA', '100', 'Manisha.Taylor@AUKLET.COM',
        149);
INSERT INTO A_customers
VALUES (104, 'Harrison', 'Sutherland', cust_address_typ
    ('6445 Bay Harbor Ln', '46254', 'Indianapolis', 'IN', 'US'),
        '+1 317 123 4126', 'us', 'AMERICA', '100', 'Harrison.Sutherland@GODWIT.COM',
        149);
INSERT INTO A_customers
VALUES (105, 'Matthias', 'MacGraw', cust_address_typ
    ('4019 W 3Rd St', '47404', 'Bloomington', 'IN', 'US'),
        '+1 812 123 4129', 'us', 'AMERICA', '100', 'Matthias.MacGraw@GOLDENEYE.COM',
        NULL);
INSERT INTO A_customers
VALUES (106, 'Matthias', 'Hannah', cust_address_typ
    ('1608 Portage Ave', '46616', 'South Bend', 'IN', 'US'),
        '+1 219 123 4136', 'us', 'AMERICA', '100', 'Matthias.Hannah@GREBE.COM',
        149);
INSERT INTO A_customers
VALUES (107, 'Matthias', 'Cruise', cust_address_typ
    ('23943 Us Highway 33', '46517', 'Elkhart', 'IN', 'US'),
        '+1 219 123 4138', 'us', 'AMERICA', '100', 'Matthias.Cruise@GROSBEAK.COM',
        NULL);
INSERT INTO A_customers
VALUES (108, 'Meenakshi', 'Mason', cust_address_typ
    ('136 E Market St # 800', '46204', 'Indianapolis', 'IN', 'US'),
        '+1 317 123 4141', 'us', 'AMERICA', '100', 'Meenakshi.Mason@JACANA.COM',
        149);
INSERT INTO A_customers
VALUES (109, 'Christian', 'Cage', cust_address_typ
    ('1905 College St', '46628', 'South Bend', 'IN', 'US'),
        '+1 219 123 4142', 'us', 'AMERICA', '100', 'Christian.Cage@KINGLET.COM',
        149);
INSERT INTO A_customers
VALUES (110, 'Charlie', 'Sutherland', cust_address_typ
    ('3512 Rockville Rd # 137C', '46222', 'Indianapolis', 'IN', 'US'),
        '+1 317 123 4146', 'us', 'AMERICA', '200', 'Charlie.Sutherland@LIMPKIN.COM',
        149);
INSERT INTO A_customers
VALUES (111, 'Charlie', 'Pacino', cust_address_typ
    ('1303 E University St', '47401', 'Bloomington', 'IN', 'US'),
        '+1 812 123 4150', 'us', 'AMERICA', '200', 'Charlie.Pacino@LONGSPUR.COM',
        149);
INSERT INTO A_customers
VALUES (112, 'Guillaume', 'Jackson', cust_address_typ
    ('115 N Weinbach Ave', '47711', 'Evansville', 'IN', 'US'),
        '+1 812 123 4151', 'us', 'AMERICA', '200', 'Guillaume.Jackson@MOORHEN.COM',
        145);
INSERT INTO A_customers
VALUES (113, 'Daniel', 'Costner', cust_address_typ
    ('2067 Rollett Ln', '47712', 'Evansville', 'IN', 'US'),
        '+1 812 123 4153', 'us', 'AMERICA', '200', 'Daniel.Costner@PARULA.COM',
        149);
INSERT INTO A_customers
VALUES (114, 'Dianne', 'Derek', cust_address_typ
    ('1105 E Allendale Dr', '47401', 'Bloomington', 'IN', 'US'),
        '+1 812 123 4157', 'us', 'AMERICA', '200', 'Dianne.Derek@SAW-WHET.COM',
        149);
INSERT INTO A_customers
VALUES (115, 'Geraldine', 'Schneider', cust_address_typ
    ('18305 Van Dyke St', '48234', 'Detroit', 'MI', 'US'),
        '+1 313 123 4159', 'us', 'AMERICA', '200', 'Geraldine.Schneider@SCAUP.COM',
        149);
INSERT INTO A_customers
VALUES (116, 'Geraldine', 'Martin', cust_address_typ
    ('Lucas Dr Bldg 348', '48242', 'Detroit', 'MI', 'US'),
        '+1 313 123 4160', 'us', 'AMERICA', '200', 'Geraldine.Martin@SCOTER.COM',
        149);
INSERT INTO A_customers
VALUES (117, 'Guillaume', 'Edwards', cust_address_typ
    ('1801 Monroe Ave Nw', '49505', 'Grand Rapids', 'MI', 'US'),
        '+1 616 123 4162', 'us', 'AMERICA', '200', 'Guillaume.Edwards@SHRIKE.COM',
        145);
INSERT INTO A_customers
VALUES (118, 'Maurice', 'Mahoney', cust_address_typ
    ('4925 Kendrick St Se', '49512', 'Grand Rapids', 'MI', 'US'),
        '+1 616 123 4181', 'us', 'AMERICA', '200', 'Maurice.Mahoney@SNIPE.COM',
        149);
INSERT INTO A_customers
VALUES (119, 'Maurice', 'Hasan', cust_address_typ
    ('3310 Dixie Ct', '48601', 'Saginaw', 'MI', 'US'),
        '+1 517 123 4191', 'us', 'AMERICA', '200', 'Maurice.Hasan@STILT.COM',
        149);
INSERT INTO A_customers
VALUES (120, 'Diane', 'Higgins', cust_address_typ
    ('113 Washington Sq N', '48933', 'Lansing', 'MI', 'US'),
        '+1 517 123 4199', 'us', 'AMERICA', '200', 'Diane.Higgins@TANAGER.COM',
        149);
INSERT INTO A_customers
VALUES (121, 'Dianne', 'Sen', cust_address_typ
    ('2500 S Pennsylvania Ave', '48910', 'Lansing', 'MI', 'US'),
        '+1 517 123 4201', 'us', 'AMERICA', '200', 'Dianne.Sen@TATTLER.COM',
        149);
INSERT INTO A_customers
VALUES (122, 'Maurice', 'Daltrey', cust_address_typ
    ('3213 S Cedar St', '48910', 'Lansing', 'MI', 'US'),
        '+1 517 123 4206', 'us', 'AMERICA', '200', 'Maurice.Daltrey@TEAL.COM',
        NULL);
INSERT INTO A_customers
VALUES (123, 'Elizabeth', 'Brown', cust_address_typ
    ('8110 Jackson Rd', '48103', 'Ann Arbor', 'MI', 'US'),
        '+1 313 123 4219', 'us', 'AMERICA', '200', 'Elizabeth.Brown@THRASHER.COM',
        149);
INSERT INTO A_customers
VALUES (124, 'Diane', 'Mason', cust_address_typ
    ('6654 W Lafayette St', '48226', 'Detroit', 'MI', 'US'),
        '+1 313 123 4222', 'us', 'AMERICA', '200', 'Diane.Mason@TROGON.COM',
        149);
INSERT INTO A_customers
VALUES (125, 'Dianne', 'Andrews', cust_address_typ
    ('27 Benton Rd', '48602', 'Saginaw', 'MI', 'US'),
        '+1 517 123 4225', 'us', 'AMERICA', '200', 'Dianne.Andrews@TURNSTONE.COM',
        149);
INSERT INTO A_customers
VALUES (126, 'Charles', 'Field', cust_address_typ
    ('8201 Livernois Ave', '48204', 'Detroit', 'MI', 'US'),
        '+1 313 123 4226', 'us', 'AMERICA', '300', 'Charles.Field@BECARD.COM',
        NULL);
INSERT INTO A_customers
VALUES (127, 'Charles', 'Broderick', cust_address_typ
    ('101 N Falahee Rd', '49203', 'Jackson', 'MI', 'US'),
        '+1 517 123 4228', 'us', 'AMERICA', '300', 'Charles.Broderick@BITTERN.COM',
        NULL);
INSERT INTO A_customers
VALUES (128, 'Isabella', 'Reed', cust_address_typ
    ('3100 E Eisenhower Pky # 100', '48108', 'Ann Arbor', 'MI', 'US'),
        '+1 313 123 4230', 'us', 'AMERICA', '300', 'Isabella.Reed@BRANT.COM',
        NULL);
INSERT INTO A_customers
VALUES (129, 'Louis', 'Jackson', cust_address_typ
    ('952 Vassar Dr', '49001', 'Kalamazoo', 'MI', 'US'),
        '+1 616 123 4234', 'us', 'AMERICA', '400', 'Louis.Jackson@CARACARA.COM',
        149);
INSERT INTO A_customers
VALUES (130, 'Louis', 'Edwards', cust_address_typ
    ('150 W Jefferson Ave # 2500', '48226', 'Detroit', 'MI', 'US'),
        '+1 313 123 4242', 'us', 'AMERICA', '400', 'Louis.Edwards@CHACHALACA.COM',
        NULL);
INSERT INTO A_customers
VALUES (131, 'Doris', 'Dutt', cust_address_typ
    ('40 Pearl St Nw # 1020', '49503', 'Grand Rapids', 'MI', 'US'),
        '+1 616 123 4245', 'us', 'AMERICA', '400', 'Doris.Dutt@CHUKAR.COM',
        NULL);
INSERT INTO A_customers
VALUES (132, 'Doris', 'Spacek', cust_address_typ
    ('1135 Catherine St', '48109', 'Ann Arbor', 'MI', 'US'),
        '+1 313 123 4248', 'us', 'AMERICA', '400', 'Doris.Spacek@FLICKER.COM',
        NULL);
INSERT INTO A_customers
VALUES (133, 'Kristin', 'Malden', cust_address_typ
    ('301 E Genesee Ave', '48607', 'Saginaw', 'MI', 'US'),
        '+1 517 123 4253', 'us', 'AMERICA', '400', 'Kristin.Malden@GODWIT.COM',
        149);
INSERT INTO A_customers
VALUES (134, 'Sissy', 'Puri', cust_address_typ
    ('9936 Dexter Ave', '48206', 'Detroit', 'MI', 'US'),
        '+1 313 123 4255', 'us', 'AMERICA', '400', 'Sissy.Puri@GREBE.COM',
        NULL);
INSERT INTO A_customers
VALUES (135, 'Doris', 'Bel Geddes', cust_address_typ
    ('1660 University Ter', '48104', 'Ann Arbor', 'MI', 'US'),
        '+1 313 123 4263', 'us', 'AMERICA', '400', 'Doris.BelGeddes@GROSBEAK.COM',
        NULL);
INSERT INTO A_customers
VALUES (136, 'Sissy', 'Warden', cust_address_typ
    ('15713 N East St', '48906', 'Lansing', 'MI', 'US'),
        '+1 517 123 4265', 'us', 'AMERICA', '400', 'Sissy.Warden@JACANA.COM',
        149);
INSERT INTO A_customers
VALUES (137, 'Elia', 'Brando', cust_address_typ
    ('555 John F Kennedy Rd', '52002', 'Dubuque', 'IA', 'US'),
        '+1 319 123 4271', 'us', 'AMERICA', '500', 'Elia.Brando@JUNCO.COM',
        149);
INSERT INTO A_customers
VALUES (138, 'Mani', 'Fonda', cust_address_typ
    ('10315 Hickman Rd', '50322', 'Des Moines', 'IA', 'US'),
        '+1 515 123 4273', 'us', 'AMERICA', '500', 'Mani.Fonda@KINGLET.COM',
        149);
INSERT INTO A_customers
VALUES (139, 'Placido', 'Kubrick', cust_address_typ
    ('2115 N Towne Ln Ne', '52402', 'Cedar Rapids', 'IA', 'US'),
        '+1 319 123 4278', 'us', 'AMERICA', '500', 'Placido.Kubrick@SCOTER.COM',
        NULL);
INSERT INTO A_customers
VALUES (140, 'Claudia', 'Kurosawa', cust_address_typ
    ('1928 Sherwood Dr', '51503', 'Council Bluffs', 'IA', 'US'),
        '+1 712 123 4280', 'us', 'AMERICA', '500', 'Claudia.Kurosawa@CHUKAR.COM',
        NULL);
INSERT INTO A_customers
VALUES (141, 'Maximilian', 'Henner', cust_address_typ
    ('2102 E Kimberly Rd', '52807', 'Davenport', 'IA', 'US'),
        '+1 319 123 4282', 'us', 'AMERICA', '500', 'Maximilian.Henner@DUNLIN.COM',
        145);
INSERT INTO A_customers
VALUES (142, 'Sachin', 'Spielberg', cust_address_typ
    ('1691 Asbury Rd', '52001', 'Dubuque', 'IA', 'US'),
        '+1 319 123 4288', 'us', 'AMERICA', '500', 'Sachin.Spielberg@GADWALL.COM',
        149);
INSERT INTO A_customers
VALUES (143, 'Sachin', 'Neeson', cust_address_typ
    ('5112 Sw 9Th St', '50315', 'Des Moines', 'IA', 'US'),
        '+1 515 123 4290', 'us', 'AMERICA', '500', 'Sachin.Neeson@GALLINULE.COM',
        149);
INSERT INTO A_customers
VALUES (144, 'Sivaji', 'Landis', cust_address_typ
    ('221 3Rd Ave Se # 300', '52401', 'Cedar Rapids', 'IA', 'US'),
        '+1 319 123 4301', 'us', 'AMERICA', '500', 'Sivaji.Landis@GOLDENEYE.COM',
        149);
INSERT INTO A_customers
VALUES (145, 'Mammutti', 'Pacino', cust_address_typ
    ('2120 Heights Dr', '54701', 'Eau Claire', 'WI', 'US'),
        '+1 745 123 4306', 'us', 'AMERICA', '500', 'Mammutti.Pacino@GREBE.COM',
        145);
INSERT INTO A_customers
VALUES (146, 'Elia', 'Fawcett', cust_address_typ
    ('8989 N Port Washington Rd', '53217', 'Milwaukee', 'WI', 'US'),
        '+1 414 123 4307', 'us', 'AMERICA', '500', 'Elia.Fawcett@JACANA.COM',
        NULL);
INSERT INTO A_customers
VALUES (147, 'Ishwarya', 'Roberts', cust_address_typ
    ('6555 W Good Hope Rd', '53223', 'Milwaukee', 'WI', 'US'),
        '+1 414 123 4308', 'us', 'AMERICA', '600', 'Ishwarya.Roberts@LAPWING.COM',
        NULL);
INSERT INTO A_customers
VALUES (148, 'Gustav', 'Steenburgen', cust_address_typ
    ('1314 N Stoughton Rd', '53714', 'Madison', 'WI', 'US'),
        '+1 608 123 4309', 'us', 'AMERICA', '600', 'Gustav.Steenburgen@PINTAIL.COM',
        149);
INSERT INTO A_customers
VALUES (149, 'Markus', 'Rampling', cust_address_typ
    ('4715 Sprecher Rd', '53704', 'Madison', 'WI', 'US'),
        '+1 608 123 4318', 'us', 'AMERICA', '600', 'Markus.Rampling@PUFFIN.COM',
        145);
INSERT INTO A_customers
VALUES (150, 'Goldie', 'Slater', cust_address_typ
    ('6161 N 64Th St', '53218', 'Milwaukee', 'WI', 'US'),
        '+1 414 123 4323', 'us', 'AMERICA', '700', 'Goldie.Slater@PYRRHULOXIA.COM',
        NULL);
INSERT INTO A_customers
VALUES (151, 'Divine', 'Aykroyd', cust_address_typ
    ('11016 W Lincoln Ave', '53227', 'Milwaukee', 'WI', 'US'),
        '+1 414 123 4324', 'us', 'AMERICA', '700', 'Divine.Aykroyd@REDSTART.COM',
        149);
INSERT INTO A_customers
VALUES (152, 'Dieter', 'Matthau', cust_address_typ
    ('8600 W National Ave', '53227', 'Milwaukee', 'WI', 'US'),
        '+1 414 123 4328', 'us', 'AMERICA', '700', 'Dieter.Matthau@VERDIN.COM',
        NULL);
INSERT INTO A_customers
VALUES (153, 'Divine', 'Sheen', cust_address_typ
    ('615 N Sherman Ave', '53704', 'Madison', 'WI', 'US'),
        ('+1 608 123 4332'), 'us', 'AMERICA', '700', 'Divine.Sheen@COWBIRD.COM',
        149);
INSERT INTO A_customers
VALUES (154, 'Frederic', 'Grodin', cust_address_typ
    ('512 E Grand Ave', '53511', 'Beloit', 'WI', 'US'),
        ('+1 608 123 4344'), 'us', 'AMERICA', '700', 'Frederic.Grodin@CREEPER.COM',
        149);
INSERT INTO A_customers
VALUES (155, 'Frederico', 'Romero', cust_address_typ
    ('600 N Broadway Fl 1', '53202', 'Milwaukee', 'WI', 'US'),
        ('+1 414 123 4347'), 'us', 'AMERICA', '700', 'Frederico.Romero@CURLEW.COM',
        145);
INSERT INTO A_customers
VALUES (156, 'Goldie', 'Montand', cust_address_typ
    ('5235 N Ironwood Ln', '53217', 'Milwaukee', 'WI', 'US'),
        ('+1 414 123 4348'), 'us', 'AMERICA', '700', 'Goldie.Montand@DIPPER.COM',
        149);
INSERT INTO A_customers
VALUES (157, 'Sidney', 'Capshaw', cust_address_typ
    ('322 E Michigan St', '53202', 'Milwaukee', 'WI', 'US'),
        ('+1 414 123 4350'), 'us', 'AMERICA', '700', 'Sidney.Capshaw@DUNLIN.COM',
        149);
INSERT INTO A_customers
VALUES (158, 'Frederico', 'Lyon', cust_address_typ
    ('1400 Bellinger St Fl 4', '54703', 'Eau Claire', 'WI', 'US'),
        ('+1 745 123 4367'), 'us', 'AMERICA', '700', 'Frederico.Lyon@FLICKER.COM',
        149);
INSERT INTO A_customers
VALUES (159, 'Eddie', 'Boyer', cust_address_typ
    ('411 E Wisconsin Ave # 2550', '53202', 'Milwaukee', 'WI', 'US'),
        ('+1 414 123 4369'), 'us', 'AMERICA', '700', 'Eddie.Boyer@GALLINULE.COM',
        NULL);
INSERT INTO A_customers
VALUES (160, 'Eddie', 'Stern', cust_address_typ
    ('808 3Rd St # 100', '54403', 'Wausau', 'WI', 'US'),
        ('+1 715 123 4372'), 'us', 'AMERICA', '700', 'Eddie.Stern@GODWIT.COM',
        149);
INSERT INTO A_customers
VALUES (161, 'Ernest', 'Weaver', cust_address_typ
    ('300 Crooks St', '54301', 'Green Bay', 'WI', 'US'),
        ('+1 414 123 4373'), 'us', 'AMERICA', '900', 'Ernest.Weaver@GROSBEAK.COM',
        149);
INSERT INTO A_customers
VALUES (162, 'Ernest', 'George', cust_address_typ
    ('122 E Dayton St', '53703', 'Madison', 'WI', 'US'),
        ('+1 608 123 4374'), 'us', 'AMERICA', '900', 'Ernest.George@LAPWING.COM',
        149);
INSERT INTO A_customers
VALUES (163, 'Ernest', 'Chandar', cust_address_typ
    ('633 S Hawley Rd', '53214', 'Milwaukee', 'WI', 'US'),
        ('+1 414 123 4376'), 'us', 'AMERICA', '900', 'Ernest.Chandar@LIMPKIN.COM',
        149);
INSERT INTO A_customers
VALUES (164, 'Charlotte', 'Kazan', cust_address_typ
    ('2122 Campbell Rd', '54601', 'La Crosse', 'WI', 'US'),
        ('+1 608 123 4378'), 'us', 'AMERICA', '1200', 'Charlotte.Kazan@MERGANSER.COM',
        149);
INSERT INTO A_customers
VALUES (165, 'Charlotte', 'Fonda', cust_address_typ
    ('3324 N Oakland Ave', '53211', 'Milwaukee', 'WI', 'US'),
        ('+1 414 123 4381'), 'us', 'AMERICA', '1200', 'Charlotte.Fonda@MOORHEN.COM',
        149);
INSERT INTO A_customers
VALUES (166, 'Dheeraj', 'Alexander', cust_address_typ
    ('666 22Nd Ave Ne', '55418', 'Minneapolis', 'MN', 'US'),
        ('+1 612 123 4397'), 'us', 'AMERICA', '1200', 'Dheeraj.Alexander@NUTHATCH.COM',
        149);
INSERT INTO A_customers
VALUES (167, 'Gerard', 'Hershey', cust_address_typ
    ('1501 Lowry Ave N', '55411', 'Minneapolis', 'MN', 'US'),
        ('+1 612 123 4399'), 'us', 'AMERICA', '1200', 'Gerard.Hershey@PARULA.COM',
        NULL);
INSERT INTO A_customers
VALUES (168, 'Hema', 'Voight', cust_address_typ
    ('113 N 1St St', '55401', 'Minneapolis', 'MN', 'US'),
        ('+1 612 123 4408'), 'us', 'AMERICA', '1200', 'Hema.Voight@PHALAROPE.COM',
        145);
INSERT INTO A_customers
VALUES (169, 'Dheeraj', 'Davis', cust_address_typ
    ('4200 Yosemite Ave S', '55416', 'Minneapolis', 'MN', 'US'),
        ('+1 612 123 4417'), 'us', 'AMERICA', '1200', 'Dheeraj.Davis@PIPIT.COM',
        NULL);
INSERT INTO A_customers
VALUES (170, 'Harry Dean', 'Fonda', cust_address_typ
    ('2800 Chicago Ave # 100', '55407', 'Minneapolis', 'MN', 'US'),
        ('+1 612 123 4419'), 'us', 'AMERICA', '1200', 'HarryDean.Fonda@PLOVER.COM',
        149);
INSERT INTO A_customers
VALUES (171, 'Hema', 'Powell', cust_address_typ
    ('200 1St St Sw', '55905', 'Rochester', 'MN', 'US'),
        ('+1 507 123 4421'), 'us', 'AMERICA', '1200', 'Hema.Powell@SANDERLING.COM',
        145);
INSERT INTO A_customers
VALUES (172, 'Harry Mean', 'Peckinpah', cust_address_typ
    ('314 W Superior St # 1015', '55802', 'Duluth', 'MN', 'US'),
        ('+1 218 123 4429'), 'us', 'AMERICA', '1200', 'HarryMean.Peckinpah@VERDIN.COM',
        149);
INSERT INTO A_customers
VALUES (173, 'Kathleen', 'Walken', cust_address_typ
    ('1409 Willow St # 600', '55403', 'Minneapolis', 'MN', 'US'),
        ('+1 612 123 4434'), 'us', 'AMERICA', '1200', 'Kathleen.Walken@VIREO.COM',
        149);
INSERT INTO A_customers
VALUES (174, 'Blake', 'Seignier', cust_address_typ
    ('2720 Brewerton Rd', '13211', 'Syracuse', 'NY', 'US'),
        ('+1 315 123 4442'), 'us', 'AMERICA', '1200', 'Blake.Seignier@GALLINULE.COM',
        149);
INSERT INTO A_customers
VALUES (175, 'Claude', 'Powell', cust_address_typ
    ('2134 W Genesee St', '13219', 'Syracuse', 'NY', 'US'),
        ('+1 315 123 4447'), 'us', 'AMERICA', '1200', 'Claude.Powell@GODWIT.COM',
        NULL);
INSERT INTO A_customers
VALUES (176, 'Faye', 'Glenn', cust_address_typ
    ('1522 Main St', '14305', 'Niagara Falls', 'NY', 'US'),
        ('+1 716 123 4457'), 'us', 'AMERICA', '1200', 'Faye.Glenn@GREBE.COM',
        149);
INSERT INTO A_customers
VALUES (177, 'Gerhard', 'Seignier', cust_address_typ
    ('49 N Pine Ave', '12203', 'Albany', 'NY', 'US'),
        ('+1 518 123 4459'), 'us', 'AMERICA', '1200', 'Gerhard.Seignier@JACANA.COM',
        149);
INSERT INTO A_customers
VALUES (178, 'Grace', 'Belushi', cust_address_typ
    ('726 Union St', '12534', 'Hudson', 'NY', 'US'),
        ('+1 518 123 4464'), 'us', 'AMERICA', '1200',
        'Grace.Belushi@KILLDEER.COM',
        NULL);
INSERT INTO A_customers
VALUES (179, 'Harry dean', 'Forrest', cust_address_typ
    ('137 Lark St', '12210', 'Albany', 'NY', 'US'),
        ('+1 518 123 4474'), 'us', 'AMERICA', '1200',
        'Harrydean.Forrest@KISKADEE.COM',
        149);
INSERT INTO A_customers
VALUES (180, 'Harry dean', 'Cage', cust_address_typ
    ('33 Fulton St', '12601', 'Poughkeepsie', 'NY', 'US'),
        ('+1 914 123 4494'), 'us', 'AMERICA', '1200',
        'Harrydean.Cage@LAPWING.COM',
        149);
INSERT INTO A_customers
VALUES (181, 'Lauren', 'Hershey', cust_address_typ
    ('2360 Maxon Rd', '12308', 'Schenectady', 'NY', 'US'),
        ('+1 518 123 4496'), 'us', 'AMERICA', '1200',
        'Lauren.Hershey@LIMPKIN.COM',
        149);
INSERT INTO A_customers
VALUES (182, 'Lauren', 'Dench', cust_address_typ
    ('85 High St', '14203', 'Buffalo', 'NY', 'US'),
        ('+1 716 123 4575'), 'us', 'AMERICA', '1200',
        'Lauren.Dench@LONGSPUR.COM',
        149);
INSERT INTO A_customers
VALUES (183, 'Lauren', 'Altman', cust_address_typ
    ('1 Palisade Ave Fl 2', '10701', 'Yonkers', 'NY', 'US'),
        ('+1 914 123 4578'), 'us', 'AMERICA', '1200', 'Lauren.Altman@MERGANSER.COM',
        145);
INSERT INTO A_customers
VALUES (184, 'Mary Beth', 'Roberts', cust_address_typ
    ('500 S Salina St # 500', '13202', 'Syracuse', 'NY', 'US'),
        ('+1 315 123 4597'), 'us', 'AMERICA', '1200', 'MaryBeth.Roberts@NUTHATCH.COM',
        NULL);
INSERT INTO A_customers
VALUES (185, 'Matthew', 'Wright', cust_address_typ
    ('33 Pine St', '14094', 'Lockport', 'NY', 'US'),
        ('+1 716 123 4599'), 'us', 'AMERICA', '1200', 'Matthew.Wright@OVENBIRD.COM',
        NULL);
INSERT INTO A_customers
VALUES (186, 'Meena', 'Alexander', cust_address_typ
    ('Po Box 2152', '14240', 'Buffalo', 'NY', 'US'),
        ('+1 716 123 4605'), 'us', 'AMERICA', '1200', 'Meena.Alexander@PARULA.COM',
        149);
INSERT INTO A_customers
VALUES (187, 'Grace', 'Dvrrie', cust_address_typ
    ('2979 Hamburg St', '12303', 'Schenectady', 'NY', 'US'),
        ('+1 518 123 4617'), 'us', 'AMERICA', '1200', 'Grace.Dvrrie@PHOEBE.COM',
        NULL);
INSERT INTO A_customers
VALUES (188, 'Charlotte', 'Buckley', cust_address_typ
    ('1790 Grand Blvd', '12309', 'Schenectady', 'NY', 'US'),
        ('+1 518 123 4618'), 'us', 'AMERICA', '1200', 'Charlotte.Buckley@PINTAIL.COM',
        NULL);
INSERT INTO A_customers
VALUES (189, 'Gena', 'Harris', cust_address_typ
    ('7 Ingelside Ln', '10605', 'White Plains', 'NY', 'US'),
        ('+1 914 123 4619'), 'us', 'AMERICA', '1200', 'Gena.Harris@PIPIT.COM',
        149);
INSERT INTO A_customers
VALUES (190, 'Gena', 'Curtis', cust_address_typ
    ('18 Glenridge Rd', '12302', 'Schenectady', 'NY', 'US'),
        ('+1 518 123 4624'), 'us', 'AMERICA', '1200', 'Gena.Curtis@PLOVER.COM',
        149);
INSERT INTO A_customers
VALUES (191, 'Maureen', 'Sanders', cust_address_typ
    ('6432 Rising Sun Ave', '19111', 'Philadelphia', 'PA', 'US'),
        ('+1 215 123 4644'), 'us', 'AMERICA', '1200', 'Maureen.Sanders@PUFFIN.COM',
        149);
INSERT INTO A_customers
VALUES (192, 'Sean', 'Stockwell', cust_address_typ
    ('Rr 10', '19606', 'Reading', 'PA', 'US'),
        ('+1 610 123 4657'), 'us', 'AMERICA', '1200', 'Sean.Stockwell@PYRRHULOXIA.COM',
        149);
INSERT INTO A_customers
VALUES (193, 'Harry dean', 'Kinski', cust_address_typ
    ('2455 Rose Garden Rd', '15220', 'Pittsburgh', 'PA', 'US'),
        ('+1 412 123 4662'), 'us', 'AMERICA', '1200', 'Harrydean.Kinski@REDPOLL.COM',
        149);
INSERT INTO A_customers
VALUES (194, 'Kathleen', 'Garcia', cust_address_typ
    ('1812 Timberline Rd', '16601', 'Altoona', 'PA', 'US'),
        ('+1 814 123 4663'), 'us', 'AMERICA', '1200', 'Kathleen.Garcia@REDSTART.COM',
        149);
INSERT INTO A_customers
VALUES (195, 'Sean', 'Olin', cust_address_typ
    ('141 Schiller St', '19601', 'Reading', 'PA', 'US'),
        ('+1 610 123 4664'), 'us', 'AMERICA', '1200', 'Sean.Olin@SCAUP.COM',
        149);
INSERT INTO A_customers
VALUES (196, 'Gerard', 'Dench', cust_address_typ
    ('1126 Pawlings Rd', '19403', 'Norristown', 'PA', 'US'),
        ('+1 610 123 4667'), 'us', 'AMERICA', '1200', 'Gerard.Dench@SCOTER.COM',
        149);
INSERT INTO A_customers
VALUES (197, 'Gerard', 'Altman', cust_address_typ
    ('55 Church Hill Rd', '19606', 'Reading', 'PA', 'US'),
        ('+1 610 123 4669'), 'us', 'AMERICA', '1200', 'Gerard.Altman@SHRIKE.COM',
        145);
INSERT INTO A_customers
VALUES (198, 'Maureen', 'de Funes', cust_address_typ
    ('354 N Prince St', '17603', 'Lancaster', 'PA', 'US'),
        ('+1 717 123 4674'), 'us', 'AMERICA', '1200', 'Maureen.deFunes@SISKIN.COM',
        149);
INSERT INTO A_customers
VALUES (199, 'Clint', 'Chapman', cust_address_typ
    ('115 Chestnut St', '19106', 'Philadelphia', 'PA', 'US'),
        ('+1 215 123 4676'), 'us', 'AMERICA', '1400', 'Clint.Chapman@SNIPE.COM',
        145);
INSERT INTO A_customers
VALUES (200, 'Clint', 'Gielgud', cust_address_typ
    ('2899 Grand Ave', '15225', 'Pittsburgh', 'PA', 'US'),
        ('+1 412 123 4681'), 'us', 'AMERICA', '1400', 'Clint.Gielgud@STILT.COM',
        149);
INSERT INTO A_customers
VALUES (201, 'Eric', 'Prashant', cust_address_typ
    ('Po Box 39', '15701', 'Indiana', 'PA', 'US'),
        ('+1 412 123 4684'), 'us', 'AMERICA', '1400', 'Eric.Prashant@TATTLER.COM',
        149);
INSERT INTO A_customers
VALUES (202, 'Ingrid', 'Welles', cust_address_typ
    ('1604 Broadway Ave', '15216', 'Pittsburgh', 'PA', 'US'),
        ('+1 412 123 4688'), 'us', 'AMERICA', '1400', 'Ingrid.Welles@TEAL.COM',
        149);
INSERT INTO A_customers
VALUES (203, 'Ingrid', 'Rampling', cust_address_typ
    ('4734 Liberty Ave', '15224', 'Pittsburgh', 'PA', 'US'),
        ('+1 412 123 4691'), 'us', 'AMERICA', '1400', 'Ingrid.Rampling@WIGEON.COM',
        145);
INSERT INTO A_customers
VALUES (204, 'Cliff', 'Puri', cust_address_typ
    ('21 Thornwood Rd', '17112', 'Harrisburg', 'PA', 'US'),
        ('+1 717 123 4692'), 'us', 'AMERICA', '1400', 'Cliff.Puri@CORMORANT.COM',
        NULL);
INSERT INTO A_customers
VALUES (205, 'Emily', 'Pollack', cust_address_typ
    ('3725 W Lake Rd', '16505', 'Erie', 'PA', 'US'),
        ('+1 814 123 4696'), 'us', 'AMERICA', '1400', 'Emily.Pollack@DIPPER.COM',
        145);
INSERT INTO A_customers
VALUES (206, 'Fritz', 'Hackman', cust_address_typ
    ('1808 4Th Ave', '16602', 'Altoona', 'PA', 'US'),
        ('+1 814 123 4697'), 'us', 'AMERICA', '1400', 'Fritz.Hackman@DUNLIN.COM',
        145);
INSERT INTO A_customers
VALUES (207, 'Cybill', 'Laughton', cust_address_typ
    ('Station Sq', '15219', 'Pittsburgh', 'PA', 'US'),
        ('+1 412 123 4700'), 'us', 'AMERICA', '1400', 'Cybill.Laughton@EIDER.COM',
        149);
INSERT INTO A_customers
VALUES (208, 'Cyndi', 'Griem', cust_address_typ
    ('4020 Garden Ave', '16508', 'Erie', 'PA', 'US'),
        ('+1 814 123 4706'), 'us', 'AMERICA', '1400', 'Cyndi.Griem@GALLINULE.COM',
        145);
INSERT INTO A_customers
VALUES (209, 'Cyndi', 'Collins', cust_address_typ
    ('100 N Peach St', '19139', 'Philadelphia', 'PA', 'US'),
        ('+1 215 123 4708'), 'us', 'AMERICA', '1400', 'Cyndi.Collins@GODWIT.COM',
        149);
INSERT INTO A_customers
VALUES (210, 'Cybill', 'Clapton', cust_address_typ
    ('835 Heister Ln', '19605', 'Reading', 'PA', 'US'),
        ('+1 610 123 4714'), 'us', 'AMERICA', '1400', 'Cybill.Clapton@GOLDENEYE.COM',
        149);
INSERT INTO A_customers
VALUES (211, 'Luchino', 'Jordan', cust_address_typ
    ('378 S Negley Ave', '15232', 'Pittsburgh', 'PA', 'US'),
        ('+1 412 123 4718'), 'us', 'AMERICA', '1500', 'Luchino.Jordan@GREBE.COM',
        149);
INSERT INTO A_customers
VALUES (212, 'Luchino', 'Falk', cust_address_typ
    ('5643 N 5Th St', '19120', 'Philadelphia', 'PA', 'US'),
        ('+1 215 123 4721'), 'us', 'AMERICA', '1500', 'Luchino.Falk@OVENBIRD.COM',
        149);
INSERT INTO A_customers
VALUES (213, 'Luchino', 'Bradford', cust_address_typ
    ('1401 W Warren Rd', '16701', 'Bradford', 'PA', 'US'),
        ('+1 814 123 4722'), 'us', 'AMERICA', '1500', 'Luchino.Bradford@PARULA.COM',
        149);
INSERT INTO A_customers
VALUES (214, 'Robin', 'Danson', cust_address_typ
    ('815 Freeport Rd', '15215', 'Pittsburgh', 'PA', 'US'),
        ('+1 412 123 4724'), 'us', 'AMERICA', '1500', 'Robin.Danson@PHAINOPEPLA.COM',
        149);
INSERT INTO A_customers
VALUES (215, 'Orson', 'Perkins', cust_address_typ
    ('327 N Washington Ave # 300', '18503', 'Scranton', 'PA', 'US'),
        ('+1 717 123 4730'), 'us', 'AMERICA', '1900', 'Orson.Perkins@PINTAIL.COM',
        149);
INSERT INTO A_customers
VALUES (216, 'Orson', 'Koirala', cust_address_typ
    ('810 Race St', '19107', 'Philadelphia', 'PA', 'US'),
        ('+1 215 123 4738'), 'us', 'AMERICA', '1900', 'Orson.Koirala@PIPIT.COM',
        149);
INSERT INTO A_customers
VALUES (217, 'Bryan', 'Huston', cust_address_typ
    ('4901 Locust Ln', '17109', 'Harrisburg', 'PA', 'US'),
        ('+1 717 123 4739'), 'us', 'AMERICA', '2300', 'Bryan.Huston@PYRRHULOXIA.COM',
        149);
INSERT INTO A_customers
VALUES (218, 'Bryan', 'Dvrrie', cust_address_typ
    ('3376 Perrysville Ave', '15214', 'Pittsburgh', 'PA', 'US'),
        ('+1 412 123 4740'), 'us', 'AMERICA', '2300', 'Bryan.Dvrrie@REDPOLL.COM',
        149);
INSERT INTO A_customers
VALUES (219, 'Ajay', 'Sen', cust_address_typ
    ('220 Penn Ave # 300', '18503', 'Scranton', 'PA', 'US'),
        ('+1 717 123 4741'), 'us', 'AMERICA', '2300', 'Ajay.Sen@TROGON.COM',
        149);
INSERT INTO A_customers
VALUES (220, 'Carol', 'Jordan', cust_address_typ
    ('135 S 18Th St # 1', '19103', 'Philadelphia', 'PA', 'US'),
        ('+1 215 123 4743'), 'us', 'AMERICA', '2300', 'Carol.Jordan@TURNSTONE.COM',
        149);
INSERT INTO A_customers
VALUES (221, 'Carol', 'Bradford', cust_address_typ
    ('522 Swede St', '19401', 'Norristown', 'PA', 'US'),
        ('+1 610 123 4744'), 'us', 'AMERICA', '2300', 'Carol.Bradford@VERDIN.COM',
        NULL);
INSERT INTO A_customers
VALUES (222, 'Cary', 'Stockwell', cust_address_typ
    ('7708 City Ave', '19151', 'Philadelphia', 'PA', 'US'),
        ('+1 215 123 4745'), 'us', 'AMERICA', '2300', 'Cary.Stockwell@VIREO.COM',
        NULL);
INSERT INTO A_customers
VALUES (223, 'Cary', 'Olin', cust_address_typ
    ('1801 Lititz Pike', '17601', 'Lancaster', 'PA', 'US'),
        ('+1 717 123 4746'), 'us', 'AMERICA', '2300', 'Cary.Olin@WATERTHRUSH.COM',
        149);
INSERT INTO A_customers
VALUES (224, 'Clara', 'Krige', cust_address_typ
    ('101 E Olney Ave', '19120', 'Philadelphia', 'PA', 'US'),
        ('+1 215 123 4748'), 'us', 'AMERICA', '2300', 'Clara.Krige@WHIMBREL.COM',
        NULL);
INSERT INTO A_customers
VALUES (225, 'Clara', 'Ganesan', cust_address_typ
    ('612 Jefferson Ave', '18510', 'Scranton', 'PA', 'US'),
        ('+1 717 123 4752'), 'us', 'AMERICA', '2300', 'Clara.Ganesan@WIGEON.COM',
        149);
INSERT INTO A_customers
VALUES (226, 'Ajay', 'Andrews', cust_address_typ
    ('223 4Th Ave # 1100', '15222', 'Pittsburgh', 'PA', 'US'),
        ('+1 412 123 4763'), 'us', 'AMERICA', '2300', 'Ajay.Andrews@YELLOWTHROAT.COM',
        149);
INSERT INTO A_customers
VALUES (227, 'Kathy', 'Prashant', cust_address_typ
    ('36 W 34Th St', '16508', 'Erie', 'PA', 'US'),
        ('+1 814 123 4766'), 'us', 'AMERICA', '2400', 'Kathy.Prashant@ANI.COM',
        149);
INSERT INTO A_customers
VALUES (228, 'Graham', 'Neeson', cust_address_typ
    ('1007 Mount Royal Blvd', '15223', 'Pittsburgh', 'PA', 'US'),
        ('+1 412 123 4767'), 'us', 'AMERICA', '2400', 'Graham.Neeson@AUKLET.COM',
        145);
INSERT INTO A_customers
VALUES (229, 'Ian', 'Chapman', cust_address_typ
    ('601 Market St', '19106', 'Philadelphia', 'PA', 'US'),
        ('+1 215 123 4768'), 'us', 'AMERICA', '2400', 'Ian.Chapman@AVOCET.COM',
        145);
INSERT INTO A_customers
VALUES (230, 'Danny', 'Wright', cust_address_typ
    ('5565 Baynton St', '19144', 'Philadelphia', 'PA', 'US'),
        ('+1 215 123 4771'), 'us', 'AMERICA', '2400', 'Danny.Wright@BITTERN.COM',
        149);
INSERT INTO A_customers
VALUES (231, 'Danny', 'Rourke', cust_address_typ
    ('5640 Fishers Ln', '20852', 'Rockville', 'MD', 'US'),
        ('+1 301 123 4794'), 'us', 'AMERICA', '2400', 'Danny.Rourke@BRANT.COM',
        149);
INSERT INTO A_customers
VALUES (232, 'Donald', 'Hunter', cust_address_typ
    ('5122 Sinclair Ln', '21206', 'Baltimore', 'MD', 'US'),
        ('+1 410 123 4795'), 'us', 'AMERICA', '2400', 'Donald.Hunter@CHACHALACA.COM',
        149);
INSERT INTO A_customers
VALUES (233, 'Graham', 'Spielberg', cust_address_typ
    ('680 Bel Air Rd', '21014', 'Bel Air', 'MD', 'US'),
        ('+1 410 123 4800'), 'us', 'AMERICA', '2400', 'Graham.Spielberg@CHUKAR.COM',
        145);
INSERT INTO A_customers
VALUES (234, 'Dan', 'Roberts', cust_address_typ
    ('4301 Ashland Ave', '21205', 'Baltimore', 'MD', 'US'),
        ('+1 410 123 4805'), 'us', 'AMERICA', '2400', 'Dan.Roberts@NUTHATCH.COM',
        149);
INSERT INTO A_customers
VALUES (235, 'Edward', 'Oates', cust_address_typ
    ('8004 Stansbury Rd', '21222', 'Baltimore', 'MD', 'US'),
        ('+1 410 012 4715'), 'us', 'AMERICA', '2400', 'Edward.Oates@OVENBIRD.COM',
        NULL);
INSERT INTO A_customers
VALUES (236, 'Edward', 'Julius', cust_address_typ
    ('10209 Yearling Dr', '20850', 'Rockville', 'MD', 'US'),
        ('+1 301 123 4809'), 'us', 'AMERICA', '2400', 'Edward.Julius@PARULA.COM',
        NULL);
INSERT INTO A_customers
VALUES (237, 'Farrah', 'Quinlan', cust_address_typ
    ('3000 Greenmount Ave', '21218', 'Baltimore', 'MD', 'US'),
        ('+1 410 123 4812'), 'us', 'AMERICA', '2400', 'Farrah.Quinlan@PHAINOPEPLA.COM',
        149);
INSERT INTO A_customers
VALUES (238, 'Farrah', 'Lange', cust_address_typ
    ('200 E Fort Ave', '21230', 'Baltimore', 'MD', 'US'),
        ('+1 410 123 4813'), 'us', 'AMERICA', '2400', 'Farrah.Lange@PHALAROPE.COM',
        149);
INSERT INTO A_customers
VALUES (239, 'Hal', 'Stockwell', cust_address_typ
    ('1262 Vocke Rd', '21502', 'Cumberland', 'MD', 'US'),
        ('+1 301 123 4814'), 'us', 'AMERICA', '2400', 'Hal.Stockwell@PHOEBE.COM',
        NULL);
INSERT INTO A_customers
VALUES (240, 'Malcolm', 'Kanth', cust_address_typ
    ('3314 Eastern Ave', '21224', 'Baltimore', 'MD', 'US'),
        ('+1 410 123 4816'), 'us', 'AMERICA', '2400', 'Malcolm.Kanth@PIPIT.COM',
        145);
INSERT INTO A_customers
VALUES (241, 'Malcolm', 'Broderick', cust_address_typ
    ('12817 Coastal Hwy', '21842', 'Ocean City', 'MD', 'US'),
        ('+1 410 123 4817'), 'us', 'AMERICA', '2400', 'Malcolm.Broderick@PLOVER.COM',
        145);
INSERT INTO A_customers
VALUES (242, 'Mary', 'Lemmon', cust_address_typ
    ('11200 Scaggsville Rd', '20723', 'Laurel', 'MD', 'US'),
        ('+1 301 123 4818'), 'us', 'AMERICA', '2400', 'Mary.Lemmon@PUFFIN.COM',
        145);
INSERT INTO A_customers
VALUES (243, 'Mary', 'Collins', cust_address_typ
    ('9435 Washington Blvd N # M', '20723', 'Laurel', 'MD', 'US'),
        ('+1 301 123 4819'), 'us', 'AMERICA', '2400', 'Mary.Collins@PYRRHULOXIA.COM',
        149);
INSERT INTO A_customers
VALUES (244, 'Matt', 'Gueney', cust_address_typ
    ('2300 Harford Rd', '21218', 'Baltimore', 'MD', 'US'),
        ('+1 410 123 4822'), 'us', 'AMERICA', '2400', 'Matt.Gueney@REDPOLL.COM',
        149);
INSERT INTO A_customers
VALUES (245, 'Max', 'von Sydow', cust_address_typ
    ('2 2Nd St # A', '21842', 'Ocean City', 'MD', 'US'),
        ('+1 410 123 4840'), 'us', 'AMERICA', '2400', 'Max.vonSydow@REDSTART.COM',
        149);
INSERT INTO A_customers
VALUES (246, 'Max', 'Schell', cust_address_typ
    ('6917 W Oklahoma Ave', '53219', 'Milwaukee', 'WI', 'US'),
        ('+1 414 123 4363'), 'us', 'AMERICA', '2400', 'Max.Schell@SANDERLING.COM',
        NULL);
INSERT INTO A_customers
VALUES (247, 'Cynda', 'Whitcraft', cust_address_typ
    ('206 S Broadway # 707', '55904', 'Rochester', 'MN', 'US'),
        ('+1 507 123 4387'), 'us', 'AMERICA', '2400', 'Cynda.Whitcraft@SANDPIPER.COM',
        149);
INSERT INTO A_customers
VALUES (248, 'Donald', 'Minnelli', cust_address_typ
    ('160 Glenwood Ave', '55405', 'Minneapolis', 'MN', 'US'),
        ('+1 612 123 4436'), 'us', 'AMERICA', '2400', 'Donald.Minnelli@SCAUP.COM',
        149);
INSERT INTO A_customers
VALUES (249, 'Hannah', 'Broderick', cust_address_typ
    ('6915 Grand Ave', '46323', 'Hammond', 'IN', 'US'),
        ('+1 219 123 4145'), 'us', 'AMERICA', '2400', 'Hannah.Broderick@SHRIKE.COM',
        149);
INSERT INTO A_customers
VALUES (250, 'Dan', 'Williams', cust_address_typ
    ('2215 Oak Industrial Dr Ne', '49505', 'Grand Rapids', 'MI', 'US'),
        ('+1 616 123 4190'), 'us', 'AMERICA', '2400', 'Dan.Williams@SISKIN.COM',
        145);
INSERT INTO A_customers
VALUES (251, 'Raul', 'Wilder', cust_address_typ
    ('65 Cadillac Sq # 2701', '48226', 'Detroit', 'MI', 'US'),
        ('+1 313 123 4241'), 'us', 'AMERICA', '2500', 'Raul.Wilder@STILT.COM',
        NULL);
INSERT INTO A_customers
VALUES (252, 'Shah Rukh', 'Field', cust_address_typ
    ('3435 Tuscany Dr Se', '49546', 'Grand Rapids', 'MI', 'US'),
        ('+1 616 123 4259'), 'us', 'AMERICA', '2500', 'ShahRukh.Field@WHIMBREL.COM',
        NULL);
INSERT INTO A_customers
VALUES (253, 'Sally', 'Bogart', cust_address_typ
    ('215 4Th Ave Se', '52401', 'Cedar Rapids', 'IA', 'US'),
        ('+1 319 123 4269'), 'us', 'AMERICA', '2500', 'Sally.Bogart@WILLET.COM',
        NULL);
INSERT INTO A_customers
VALUES (254, 'Bruce', 'Bates', cust_address_typ
    ('1751 Madison Ave', '51503', 'Council Bluffs', 'IA', 'US'),
        ('+1 712 123 4284'), 'us', 'AMERICA', '3500', 'Bruce.Bates@COWBIRD.COM',
        NULL);
INSERT INTO A_customers
VALUES (255, 'Brooke', 'Shepherd', cust_address_typ
    ('810 1St Ave', '51501', 'Council Bluffs', 'IA', 'US'),
        ('+1 712 123 4289'), 'us', 'AMERICA', '3500', 'Brooke.Shepherd@KILLDEER.COM',
        NULL);
INSERT INTO A_customers
VALUES (256, 'Ben', 'de Niro', cust_address_typ
    ('500 W Oklahoma Ave', '53207', 'Milwaukee', 'WI', 'US'),
        ('+1 414 123 4312'), 'us', 'AMERICA', '3500', 'Ben.deNiro@KINGLET.COM',
        149);
INSERT INTO A_customers
VALUES (257, 'Emmet', 'Walken', cust_address_typ
    ('4811 S 76Th St # 205', '53220', 'Milwaukee', 'WI', 'US'),
        ('+1 414 123 4364'), 'us', 'AMERICA', '3600', 'Emmet.Walken@LIMPKIN.COM',
        145);
INSERT INTO A_customers
VALUES (258, 'Ellen', 'Palin', cust_address_typ
    ('310 Broadway St', '56308', 'Alexandria', 'MN', 'US'),
        ('+1 320 123 4385'), 'us', 'AMERICA', '3600', 'Ellen.Palin@LONGSPUR.COM',
        149);
INSERT INTO A_customers
VALUES (259, 'Denholm', 'von Sydow', cust_address_typ
    ('1721 E Lake St', '55407', 'Minneapolis', 'MN', 'US'),
        ('+1 612 123 4407'), 'us', 'AMERICA', '3600', 'Denholm.vonSydow@MERGANSER.COM',
        145);
INSERT INTO A_customers
VALUES (260, 'Ellen', 'Khan', cust_address_typ
    ('255 Great Arrow Ave', '14207', 'Buffalo', 'NY', 'US'),
        ('+1 716 123 4456'), 'us', 'AMERICA', '3600', 'Ellen.Khan@VERDIN.COM',
        149);
INSERT INTO A_customers
VALUES (261, 'Emmet', 'Garcia', cust_address_typ
    ('800 Carter St', '14621', 'Rochester', 'NY', 'US'),
        ('+1 716 123 4582'), 'us', 'AMERICA', '3600', 'Emmet.Garcia@VIREO.COM',
        145);
INSERT INTO A_customers
VALUES (262, 'Fred', 'Reynolds', cust_address_typ
    ('6640 Campbell Blvd', '14094', 'Lockport', 'NY', 'US'),
        ('+1 716 123 4627'), 'us', 'AMERICA', '3600', 'Fred.Reynolds@WATERTHRUSH.COM',
        149);
INSERT INTO A_customers
VALUES (263, 'Fred', 'Lithgow', cust_address_typ
    ('802 North Ave', '15209', 'Pittsburgh', 'PA', 'US'),
        ('+1 412 123 4677'), 'us', 'AMERICA', '3600', 'Fred.Lithgow@WHIMBREL.COM',
        NULL);
INSERT INTO A_customers
VALUES (264, 'George', 'Adjani', cust_address_typ
    ('1136 Arch St', '19107', 'Philadelphia', 'PA', 'US'),
        ('+1 215 123 4702'), 'us', 'AMERICA', '3600', 'George.Adjani@WILLET.COM',
        149);
INSERT INTO A_customers
VALUES (265, 'Irene', 'Laughton', cust_address_typ
    ('6Th And Master St', '19122', 'Philadelphia', 'PA', 'US'),
        ('+1 215 123 4749'), 'us', 'AMERICA', '3600', 'Irene.Laughton@ANHINGA.COM',
        149);
INSERT INTO A_customers
VALUES (266, 'Prem', 'Cardinale', cust_address_typ
    ('Rt 6 E', '16365', 'Warren', 'PA', 'US'),
        ('+1 814 123 4755'), 'us', 'AMERICA', '3700', 'Prem.Cardinale@BITTERN.COM',
        145);
INSERT INTO A_customers
VALUES (267, 'Prem', 'Walken', cust_address_typ
    ('1924 Bedford St', '21502', 'Cumberland', 'MD', 'US'),
        ('+1 301 123 4831'), 'us', 'AMERICA', '3700', 'Prem.Walken@BRANT.COM',
        145);
INSERT INTO A_customers
VALUES (268, 'Kyle', 'Schneider', cust_address_typ
    ('2674 Collingwood St', '48206', 'Detroit', 'MI', 'US'),
        ('+1 313 123 4167'), 'us', 'AMERICA', '3700', 'Kyle.Schneider@DUNLIN.COM',
        149);
INSERT INTO A_customers
VALUES (269, 'Kyle', 'Martin', cust_address_typ
    ('2713 N Bendix Dr', '46628', 'South Bend', 'IN', 'US'),
        ('+1 219 123 4116'), 'us', 'AMERICA', '3700', 'Kyle.Martin@EIDER.COM',
        149);
INSERT INTO A_customers
VALUES (270, 'Meg', 'Derek', cust_address_typ
    ('23985 Bedford Rd N', '49017', 'Battle Creek', 'MI', 'US'),
        ('+1 616 123 4166'), 'us', 'AMERICA', '3700', 'Meg.Derek@FLICKER.COM',
        NULL);
INSERT INTO A_customers
VALUES (271, 'Shelley', 'Peckinpah', cust_address_typ
    ('752 W Huron St', '48341', 'Pontiac', 'MI', 'US'),
        ('+1 810 123 4212'), 'us', 'AMERICA', '3700', 'Shelley.Peckinpah@GODWIT.COM',
        149);
INSERT INTO A_customers
VALUES (272, 'Prem', 'Garcia', cust_address_typ
    ('660 Woodward Ave # 2290', '48226', 'Detroit', 'MI', 'US'),
        ('+1 313 123 4240'), 'us', 'AMERICA', '3700', 'Prem.Garcia@JACANA.COM',
        145);
INSERT INTO A_customers
VALUES (273, 'Bo', 'Hitchcock', cust_address_typ
    ('1330 N Memorial Dr', '53404', 'Racine', 'WI', 'US'),
        ('+1 414 123 4340'), 'us', 'AMERICA', '5000', 'Bo.Hitchcock@ANHINGA.COM',
        NULL);
INSERT INTO A_customers
VALUES (274, 'Bob', 'McCarthy', cust_address_typ
    ('701 Seneca St', '14210', 'Buffalo', 'NY', 'US'),
        ('+1 716 123 4485'), 'us', 'AMERICA', '5000', 'Bob.McCarthy@ANI.COM',
        NULL);
INSERT INTO A_customers
VALUES (275, 'Dom', 'McQueen', cust_address_typ
    ('8 Automation Ln', '12205', 'Albany', 'NY', 'US'),
        ('+1 518 123 4532'), 'us', 'AMERICA', '5000', 'Dom.McQueen@AUKLET.COM',
        145);
INSERT INTO A_customers
VALUES (276, 'Dom', 'Hoskins', cust_address_typ
    ('811 N Brandywine Ave', '12308', 'Schenectady', 'NY', 'US'),
        ('+1 518 123 4562'), 'us', 'AMERICA', '5000', 'Dom.Hoskins@AVOCET.COM',
        145);
INSERT INTO A_customers
VALUES (277, 'Don', 'Siegel', cust_address_typ
    ('2904 S Salina St', '13205', 'Syracuse', 'NY', 'US'),
        ('+1 315 123 4585'), 'us', 'AMERICA', '5000', 'Don.Siegel@BITTERN.COM',
        149);
INSERT INTO A_customers
VALUES (278, 'Gvtz', 'Bradford', cust_address_typ
    ('3025 Sussex Ave', '15226', 'Pittsburgh', 'PA', 'US'),
        ('+1 412 123 4659'), 'us', 'AMERICA', '5000', 'Gvtz.Bradford@BULBUL.COM',
        NULL);
INSERT INTO A_customers
VALUES (279, 'Holly', 'Kurosawa', cust_address_typ
    ('932 High St', '17603', 'Lancaster', 'PA', 'US'),
        ('+1 717 123 4679'), 'us', 'AMERICA', '5000', 'Holly.Kurosawa@CARACARA.COM',
        NULL);
INSERT INTO A_customers
VALUES (280, 'Rob', 'MacLaine', cust_address_typ
    ('5344 Haverford Ave', '19139', 'Philadelphia', 'PA', 'US'),
        ('+1 215 123 4709'), 'us', 'AMERICA', '5000', 'Rob.MacLaine@COOT.COM',
        149);
INSERT INTO A_customers
VALUES (281, 'Don', 'Barkin', cust_address_typ
    ('6959 Tulip St', '19135', 'Philadelphia', 'PA', 'US'),
        ('+1 215 123 4751'), 'us', 'AMERICA', '5000', 'Don.Barkin@CORMORANT.COM',
        149);
INSERT INTO A_customers
VALUES (282, 'Kurt', 'Danson', cust_address_typ
    ('511 S Central Ave # A', '21202', 'Baltimore', 'MD', 'US'),
        ('+1 410 123 4807'), 'us', 'AMERICA', '5000', 'Kurt.Danson@COWBIRD.COM',
        149);
INSERT INTO A_customers
VALUES (283, 'Kurt', 'Heard', cust_address_typ
    ('400 E Joppa Rd', '21286', 'Baltimore', 'MD', 'US'),
        ('+1 410 123 4829'), 'us', 'AMERICA', '5000', 'Kurt.Heard@CURLEW.COM',
        NULL);
INSERT INTO A_customers
VALUES (308, 'Glenda', 'Dunaway', cust_address_typ
    ('1795 Wu Meng', '21191', 'Muang Chonburi', '', 'CN'),
        ('+86 811 012 4093'), 'zhs', 'CHINA', '1200', 'Glenda.Dunaway@DOWITCHER.COM',
        149);
INSERT INTO A_customers
VALUES (309, 'Glenda', 'Bates', cust_address_typ
    ('1796 Tsing Tao', '11111', 'Muang Nonthaburi', '', 'CN'),
        ('+86 123 012 4095'), 'zhs', 'CHINA', '1200', 'Glenda.Bates@DIPPER.COM',
        149);
INSERT INTO A_customers
VALUES (323, 'G�tz', 'Falk', cust_address_typ
    ('1810 Tucker Crt', '361181', 'Mumbai', '', 'IN'),
        ('+91 80 012 4123'), 'hi', 'INDIA', '5000',
        'G�tz.Falk@VEERY.COM',
        NULL);
INSERT INTO A_customers
VALUES (326, 'Hal', 'Olin', cust_address_typ
    ('Walpurgisstr 69', '81243', 'Munich', '', 'DE'),
        ('+49 89 012 4129'), 'd', 'GERMANY', '2400',
        'Hal.Olin@FLICKER.COM',
        149);
INSERT INTO A_customers
VALUES (327, 'Hannah', 'Kanth', cust_address_typ
    ('Sendlinger Tor 4', '81696', 'Munich', '', 'DE'),
        ('+49 90 012 4131'), 'd', 'GERMANY', '2400',
        'Hannah.Kanth@GADWALL.COM',
        149);
INSERT INTO A_customers
VALUES (328, 'Hannah', 'Field', cust_address_typ
    ('Theresienstr 15', '81999', 'Munich', '', 'DE'),
        ('+49 91 012 4133'), 'd', 'GERMANY', '2400',
        'Hannah.Field@GALLINULE.COM',
        149);
INSERT INTO A_customers
VALUES (333, 'Margret', 'Powell', cust_address_typ
    ('Via Frenzy 6903', '361196', 'Roma', '', 'IT'),
        ('+39 6 012 4543'), 'i', 'ITALY', '1200',
        'Margret.Powell@ANI.COM',
        NULL);
INSERT INTO A_customers
VALUES (334, 'Harry Mean', 'Taylor', cust_address_typ
    ('1822 Ironweed St', '91261', 'Toronto', 'ONT', 'CA'),
        ('+1 416 012 4147'), 'us', 'AMERICA', '1200', 'HarryMean.Taylor@REDPOLL.COM',
        149);
INSERT INTO A_customers
VALUES (335, 'Margrit', 'Garner', cust_address_typ
    ('Via Luminosa 162', '361197', 'Firenze', '', 'IT'),
        ('+39 55 012 4547'), 'i', 'ITALY', '500', 'Margrit.Garner@STILT.COM',
        149);
INSERT INTO A_customers
VALUES (337, 'Maria', 'Warden', cust_address_typ
    ('Via Notoriosa 1932 Rd', '361198', 'Firenze', '', 'IT'),
        ('+39 55 012 4551'), 'i', 'ITALY', '500', 'Maria.Warden@TANAGER.COM',
        149);
INSERT INTO A_customers
VALUES (339, 'Marilou', 'Landis', cust_address_typ
    ('Via Notoriosa 1941', '361199', 'Firenze', '', 'IT'),
        ('+39 55 012 4555'), 'i', 'ITALY', '500', 'Marilou.Landis@TATTLER.COM',
        149);
INSERT INTO A_customers
VALUES (361, 'Marilou', 'Chapman', cust_address_typ
    ('Via Notoriosa 1942', '361200', 'Firenze', '', 'IT'),
        ('+39 55 012 4559'), 'i', 'ITALY', '500', 'Marilou.Chapman@TEAL.COM',
        145);
INSERT INTO A_customers
VALUES (363, 'Kathy', 'Lambert', cust_address_typ
    ('Via Delle Grazie 11', '361225', 'Tellaro', '', 'IT'),
        ('+39 10 012 4363'), 'i', 'ITALY', '2400', 'Kathy.Lambert@COOT.COM',
        145);
INSERT INTO A_customers
VALUES (360, 'Helmut', 'Capshaw', cust_address_typ
    ('1831 No Wong', '111181', 'Peking', '', 'CN'),
        ('+86 10 012 4165'), 'zhs', 'CHINA', '3600', 'Helmut.Capshaw@TROGON.COM',
        145);
INSERT INTO A_customers
VALUES (341, 'Keir', 'George', cust_address_typ
    ('Via Dolorosa 69', '361229', 'Tellaro', '', 'IT'),
        ('+39 10 012 4365'), 'i', 'ITALY', '700', 'Keir.George@VIREO.COM',
        NULL);
INSERT INTO A_customers
VALUES (342, 'Marlon', 'Laughton', cust_address_typ
    ('Via Notoriosa 1943', '361201', 'Firenze', '', 'IT'),
        ('+39 55 012 4565'), 'i', 'ITALY', '2400', 'Marlon.Laughton@CORMORANT.COM',
        149);
INSERT INTO A_customers
VALUES (343, 'Keir', 'Chandar', cust_address_typ
    ('Via Luminosa 162', '361231', 'Tellaro', '', 'IT'),
        ('+39 10 012 4367'), 'i', 'ITALY', '700', 'Keir.Chandar@WATERTHRUSH.COM',
        149);
INSERT INTO A_customers
VALUES (344, 'Marlon', 'Godard', cust_address_typ
    ('2017 Convoy St', '876508', 'Tokyo', '', 'JP'),
        ('+81 565 012 4567'), 'ja', 'JAPAN', '2400', 'Marlon.Godard@MOORHEN.COM',
        149);
INSERT INTO A_customers
VALUES (345, 'Keir', 'Weaver', cust_address_typ
    ('Via Di Firenze 231', '361228', 'Tellaro', '', 'IT'),
        ('+39 10 012 4369'), 'i', 'ITALY', '700', 'Keir.Weaver@WHIMBREL.COM',
        NULL);
INSERT INTO A_customers
VALUES (346, 'Marlon', 'Clapton', cust_address_typ
    ('Via Notoriosa 1949', '361202', 'Firenze', '', 'IT'),
        ('+39 55 012 4569'), 'i', 'ITALY', '2400', 'Marlon.Clapton@COWBIRD.COM',
        149);
INSERT INTO A_customers
VALUES (347, 'Kelly', 'Quinlan', cust_address_typ
    ('Via Frenzy 6903', '361230', 'Tellaro', '', 'IT'),
        ('+39 10 012 4371'), 'i', 'ITALY', '3600',
        'Kelly.Quinlan@PYRRHULOXIA.COM',
        149);
INSERT INTO A_customers
VALUES (348, 'Kelly', 'Lange', cust_address_typ
    ('Piazza Del Congresso 22', '361219', 'San Giminiano', '', 'IT'),
        ('+39 49 012 4373'), 'i', 'ITALY', '3600',
        'Kelly.Lange@SANDPIPER.COM',
        149);
INSERT INTO A_customers
VALUES (349, 'Ken', 'Glenn', cust_address_typ
    ('Piazza Quattre Stagioni 4', '361220', 'San Giminiano', '', 'IT'),
        ('+39 49 012 4375'), 'i', 'ITALY', '3600',
        'Ken.Glenn@SAW-WHET.COM',
        149);
INSERT INTO A_customers
VALUES (350, 'Ken', 'Chopra', cust_address_typ
    ('Piazza Cacchiatore 23', '361218', 'San Giminiano', '', 'IT'),
        ('+39 49 012 4377'), 'i', 'ITALY', '3600',
        'Ken.Chopra@SCAUP.COM',
        149);
INSERT INTO A_customers
VALUES (351, 'Ken', 'Wenders', cust_address_typ
    ('Via Notoriosa 1932', '361232', 'Tellaro', '', 'IT'),
        ('+39 10 012 4379'), 'i', 'ITALY', '3600',
        'Ken.Wenders@REDPOLL.COM',
        149);
INSERT INTO A_customers
VALUES (352, 'Kenneth', 'Redford', cust_address_typ
    ('Via Notoriosa 1949', '361236', 'Ventimiglia', '', 'IT'),
        ('+39 10 012 4381'), 'i', 'ITALY', '3600',
        'Kenneth.Redford@REDSTART.COM',
        149);
INSERT INTO A_customers
VALUES (378, 'Meg', 'Sen', cust_address_typ
    ('2033 Spartacus St', '', 'Samutprakarn', '', 'TH'),
        ('+66 76 012 4633'), 'th', 'THAILAND', '3700',
        'Meg.Sen@COWBIRD.COM',
        149);
INSERT INTO A_customers
VALUES (380, 'Meryl', 'Holden', cust_address_typ
    ('2034 Sabrina Rd', '361182', 'Samutprakarn', '', 'IN'),
        ('+91 80 012 4637'), 'hi', 'INDIA', '3700',
        'Meryl.Holden@DIPPER.COM',
        149);
INSERT INTO A_customers
VALUES (447, 'Richard', 'Coppola', cust_address_typ
    ('Piazza Svizzera', '361211', 'Milano', '', 'IT'),
        ('+39 2 012 4771'), 'i', 'ITALY', '500', 'Richard.Coppola@SISKIN.COM',
        NULL);
INSERT INTO A_customers
VALUES (448, 'Richard', 'Winters', cust_address_typ
    ('Ruella Delle Spiriti', '361212', 'Milano', '', 'IT'),
        ('+39 2 012 4773'), 'i', 'ITALY', '500', 'Richard.Winters@SNIPE.COM',
        149);
INSERT INTO A_customers
VALUES (449, 'Rick', 'Romero', cust_address_typ
    ('Via Del Disegno 194', '361213', 'Milano', '', 'IT'),
        ('+39 2 012 4775'), 'i', 'ITALY', '1500', 'Rick.Romero@LONGSPUR.COM',
        145);
INSERT INTO A_customers
VALUES (450, 'Rick', 'Lyon', cust_address_typ
    ('Via Delle Capeletti 52', '361214', 'San Giminiano', '', 'IT'),
        ('+39 49 012 4777'), 'i', 'ITALY', '1500', 'Rick.Lyon@MERGANSER.COM',
        149);
INSERT INTO A_customers
VALUES (451, 'Ridley', 'Hackman', cust_address_typ
    ('Via Delle Grazie 11', '361215', 'San Giminiano', '', 'IT'),
        ('+39 49 012 4779'), 'i', 'ITALY', '700', 'Ridley.Hackman@ANHINGA.COM',
        145);
INSERT INTO A_customers
VALUES (452, 'Ridley', 'Coyote', cust_address_typ
                                     ('Via Delli Capelli 2', '361216', 'San Giminiano', '', 'IT')
    ('+39 49 012 4781'), 'i', 'ITALY', '700', 'Ridley.Coyote@ANI.COM',
        NULL);
INSERT INTO A_customers
VALUES (453, 'Ridley', 'Young', cust_address_typ
    ('1592 Silverado St', '361123', 'Bangalore', 'Kar', 'IN'),
        ('+91 80 012 4783'), 'hi', 'INDIA', '700', 'Ridley.Young@CHUKAR.COM',
        149);
INSERT INTO A_customers
VALUES (454, 'Rob', 'Russell', cust_address_typ
    ('1593 Silverado St', '361112', 'Bangalore', 'Kar', 'IN'),
        ('+91 80 012 4785'), 'hi', 'INDIA', '5000',
        'Rob.Russell@VERDIN.COM',
        NULL);
INSERT INTO A_customers
VALUES (458, 'Robert', 'de Niro', cust_address_typ
    ('1597 Legend St', '', 'Mysore', 'Kar', 'IN'),
        ('+91 80 012 4793'), 'hi', 'INDIA', '3700',
        'Robert.deNiro@DOWITCHER.COM',
        NULL);
INSERT INTO A_customers
VALUES (463, 'Robin', 'Adjani', cust_address_typ
    ('1602 Sholay St', '', 'Chennai', 'Tam', 'IN'),
        ('+91 80 012 4803'), 'hi', 'INDIA', '1500', 'Robin.Adjani@MOORHEN.COM',
        149);
INSERT INTO A_customers
VALUES (466, 'Rodolfo', 'Hershey', cust_address_typ
    ('1605 Bazigar Crt', '', 'Pune', '', 'IN'),
        ('+91 80 012 4809'), 'hi', 'INDIA', '5000',
        'Rodolfo.Hershey@VIREO.COM',
        NULL);
INSERT INTO A_customers
VALUES (467, 'Rodolfo', 'Dench', cust_address_typ
    ('1606 Sangam Blvd', '361196', 'New Delhi', '', 'IN'),
        ('+91 11 012 4811'), 'hi', 'INDIA', '5000',
        'Rodolfo.Dench@SCOTER.COM',
        149);
INSERT INTO A_customers
VALUES (468, 'Rodolfo', 'Altman', cust_address_typ
    ('1607 Sangam Blvd', '361114', 'New Delhi', '', 'IN'),
        ('+91 11 012 4813'), 'hi', 'INDIA', '5000',
        'Rodolfo.Altman@SHRIKE.COM',
        145);
INSERT INTO A_customers
VALUES (470, 'Roger', 'Mastroianni', cust_address_typ
    ('1609 Pakija Rd', '', 'New Delhi', '', 'IN'),
        ('+91 11 012 4817'), 'hi', 'INDIA', '3700',
        'Roger.Mastroianni@CREEPER.COM',
        149);
INSERT INTO A_customers
VALUES (473, 'Rolf', 'Ashby', cust_address_typ
    ('1612 Talaivar St', '', 'Chennai', 'Tam', 'IN'),
        ('+91 80 012 4823'), 'hi', 'INDIA', '5000',
        'Rolf.Ashby@WATERTHRUSH.COM',
        NULL);
INSERT INTO A_customers
VALUES (474, 'Romy', 'Sharif', cust_address_typ
    ('1613 Victoria St', '', 'Calcutta', '', 'IN'),
        ('+91 33 012 4825'), 'hi', 'INDIA', '5000',
        'Romy.Sharif@SNIPE.COM',
        145);
INSERT INTO A_customers
VALUES (475, 'Romy', 'McCarthy', cust_address_typ
    ('1614 Gitanjali Rd', '361168', 'Calcutta', '', 'IN'),
        ('+91 33 012 4827'), 'hi', 'INDIA', '5000',
        'Romy.McCarthy@STILT.COM',
        145);
INSERT INTO A_customers
VALUES (476, 'Rosanne', 'Hopkins', cust_address_typ
    ('1615 Crackers Crt', '361168', 'Chennai - India', '', 'IN'),
        ('+91 80 012 4829'), 'hi', 'INDIA', '300', 'Rosanne.Hopkins@ANI.COM',
        149);
INSERT INTO A_customers
VALUES (477, 'Rosanne', 'Douglas', cust_address_typ
    ('1616 Mr. India Ln', '361168', 'Bombay - India', 'Kar', 'IN'),
        ('+91 22 012 4831'), 'hi', 'INDIA', '300', 'Rosanne.Douglas@ANHINGA.COM',
        149);
INSERT INTO A_customers
VALUES (478, 'Rosanne', 'Baldwin', cust_address_typ
    ('1617 Crackers St', '361168', 'Bangalore - India', 'Kar', 'IN'),
        ('+91 80 012 4833'), 'hi', 'INDIA', '300', 'Rosanne.Baldwin@AUKLET.COM',
        149);
INSERT INTO A_customers
VALUES (479, 'Roxanne', 'Shepherd', cust_address_typ
    ('1618 Villains St', '361168', 'New Delhi - India', '', 'IN'),
        ('+91 11 012 4835'), 'hi', 'INDIA', '1200',
        'Roxanne.Shepherd@DUNLIN.COM',
        149);
INSERT INTO A_customers
VALUES (480, 'Roxanne', 'Michalkow', cust_address_typ
    ('1619 Bowlers Rd', '361168', 'Chandigarh', 'Har', 'IN'),
        ('+91 172 012 4837'), 'hi', 'INDIA', '1200', 'Roxanne.Michalkow@EIDER.COM',
        149);
INSERT INTO A_customers
VALUES (481, 'Roy', 'Hulce', cust_address_typ
    ('1620 Sixers Crt', '361168', 'Bombay', 'Kar', 'IN'),
        ('+91 22 012 4839'), 'hi', 'INDIA', '5000',
        'Roy.Hulce@SISKIN.COM',
        NULL);
INSERT INTO A_customers
VALUES (482, 'Roy', 'Dunaway', cust_address_typ
    ('1622 Roja St', '361168', 'Chennai', 'Tam', 'IN'),
        ('+91 80 012 4841'), 'hi', 'INDIA', '5000',
        'Roy.Dunaway@WHIMBREL.COM',
        149);
INSERT INTO A_customers
VALUES (483, 'Roy', 'Bates', cust_address_typ
    ('1623 Hey Ram St', '361168', 'Chennai - India', '', 'IN'),
        ('+91 80 012 4843'), 'hi', 'INDIA', '5000',
        'Roy.Bates@WIGEON.COM',
        NULL);
INSERT INTO A_customers
VALUES (487, 'Rufus', 'Dvrrie', cust_address_typ
    ('1627 Sowdagar St', '361168', 'New Delhi', '', 'IN'),
        ('+91 11 012 4851'), 'hi', 'INDIA', '1900',
        'Rufus.Dvrrie@PLOVER.COM',
        NULL);
INSERT INTO A_customers
VALUES (488, 'Rufus', 'Belushi', cust_address_typ
    ('1628 Pataudi St', '361168', 'New Delhi', '', 'IN'),
        ('+91 11 012 4853'), 'hi', 'INDIA', '1900',
        'Rufus.Belushi@PUFFIN.COM',
        NULL);
INSERT INTO A_customers
VALUES (492, 'Sally', 'Edwards', cust_address_typ
    ('1632 Splash St', '361168', 'Chandigarh', 'Har', 'IN'),
        ('+91 172 012 4861'), 'hi', 'INDIA', '2500',
        'Sally.Edwards@TURNSTONE.COM',
        NULL);
INSERT INTO A_customers
VALUES (496, 'Scott', 'Jordan', cust_address_typ
    ('1636 Pretty Blvd', '361168', 'Bangalore', 'Kar', 'IN'),
        ('+91 80 012 4869'), 'hi', 'INDIA', '5000', 'Scott.Jordan@WILLET.COM',
        149);
INSERT INTO A_customers
VALUES (605, 'Shammi', 'Pacino', cust_address_typ
    ('1646 Brazil Blvd', '361168', 'Chennai', 'Tam', 'IN'),
        ('+91 80 012 4887'), 'hi', 'INDIA', '500', 'Shammi.Pacino@BITTERN.COM',
        145);
INSERT INTO A_customers
VALUES (606, 'Sharmila', 'Kazan', cust_address_typ
    ('1647 Suspense St', '361168', 'Cochin', 'Ker', 'IN'),
        ('+91 80 012 4889'), 'hi', 'INDIA', '500', 'Sharmila.Kazan@BRANT.COM',
        145);
INSERT INTO A_customers
VALUES (607, 'Sharmila', 'Fonda', cust_address_typ
    ('1648 Anamika St', '361168', 'Cochin', 'Ker', 'IN'),
        ('+91 80 012 4891'), 'hi', 'INDIA', '500', 'Sharmila.Fonda@BUFFLEHEAD.COM',
        145);
INSERT INTO A_customers
VALUES (609, 'Shelley', 'Taylor', cust_address_typ
    ('1650 Teesri Manjil Crt', '361168', 'Kashmir', '', 'IN'),
        ('+91 141 012 4895'), 'hi', 'INDIA', '3700',
        'Shelley.Taylor@CURLEW.COM',
        NULL);
INSERT INTO A_customers
VALUES (615, 'Shyam', 'Plummer', cust_address_typ
    ('1656 Veterans Rd', '361168', 'Chennai', 'Tam', 'IN'),
        ('+91 80 012 4907'), 'hi', 'INDIA', '2500', 'Shyam.Plummer@VEERY.COM',
        145);
INSERT INTO A_customers
VALUES (621, 'Silk', 'Kurosawa', cust_address_typ
    ('1662 Talaivar St', '361168', 'Chennai', 'Tam', 'IN'),
        ('+91 80 012 4919'), 'hi', 'INDIA', '1500', 'Silk.Kurosawa@NUTHATCH.COM',
        NULL);
INSERT INTO A_customers
VALUES (627, 'Sivaji', 'Gielgud', cust_address_typ
    ('1667 2010 St', '61311', 'Batavia', 'Ker', 'IN'),
        ('+91 80 012 4931'), 'hi', 'INDIA', '500', 'Sivaji.Gielgud@BULBUL.COM',
        NULL);
INSERT INTO A_customers
VALUES (712, 'M. Emmet', 'Stockwell', cust_address_typ
    ('Piazza Del Congresso 22', '361185', 'Roma', '', 'IT'),
        ('+39 6 012 4501'), 'i', 'ITALY', '3700',
        'M.Emmet.Stockwell@COOT.COM',
        145);
INSERT INTO A_customers
VALUES (713, 'M. Emmet', 'Olin', cust_address_typ
    ('Piazza Quattre Stagioni 4', '361186', 'Roma', '', 'IT'),
        ('+39 6 012 4503'), 'i', 'ITALY', '3700',
        'M.Emmet.Olin@CORMORANT.COM',
        145);
INSERT INTO A_customers
VALUES (715, 'Malcolm', 'Field', cust_address_typ
    ('Piazza Svizzera', '361187', 'Roma', '', 'IT'),
        ('+39 6 012 4507'), 'i', 'ITALY', '2400',
        'Malcolm.Field@DOWITCHER.COM',
        145);
INSERT INTO A_customers
VALUES (717, 'Mammutti', 'Sutherland', cust_address_typ
    ('Ruella Delle Spiriti', '361188', 'Roma', '', 'IT'),
        ('+39 6 012 4511'), 'i', 'ITALY', '500',
        'Mammutti.Sutherland@TOWHEE.COM',
        145);
INSERT INTO A_customers
VALUES (719, 'Mani', 'Kazan', cust_address_typ
    ('Via Del Disegno 194', '361189', 'Roma', '', 'IT'),
        ('+39 6 012 4515'), 'i', 'ITALY', '500', 'Mani.Kazan@TROGON.COM',
        149);
INSERT INTO A_customers
VALUES (721, 'Mani', 'Buckley', cust_address_typ
    ('Via Delle Capeletti 52', '361190', 'Roma', '', 'IT'),
        ('+39 6 012 4519'), 'i', 'ITALY', '500', 'Mani.Buckley@TURNSTONE.COM',
        149);
INSERT INTO A_customers
VALUES (727, 'Margaret', 'Ustinov', cust_address_typ
    ('Via Dello Croce 93', '361193', 'Roma', '', 'IT'),
        ('+39 6 012 4531'), 'i', 'ITALY', '1200', 'Margaret.Ustinov@ANHINGA.COM',
        149);
INSERT INTO A_customers
VALUES (729, 'Margaux', 'Krige', cust_address_typ
    ('Via Di Firenze 231', '361194', 'Roma', '', 'IT'),
        ('+39 6 012 4535'), 'i', 'ITALY', '2400',
        'Margaux.Krige@DUNLIN.COM',
        NULL);
INSERT INTO A_customers
VALUES (731, 'Margaux', 'Capshaw', cust_address_typ
    ('Via Dolorosa 69', '361195', 'Roma', '', 'IT'),
        ('+39 6 012 4539'), 'i', 'ITALY', '2400',
        'Margaux.Capshaw@EIDER.COM',
        NULL);
INSERT INTO A_customers
VALUES (754, 'Kevin', 'Goodman', cust_address_typ
    ('Via Notoriosa 1942', '361234', 'Ventimiglia', '', 'IT'),
        ('+39 10 012 4385'), 'i', 'ITALY', '700', 'Kevin.Goodman@WIGEON.COM',
        145);
INSERT INTO A_customers
VALUES (755, 'Kevin', 'Cleveland', cust_address_typ
    ('Via Notoriosa 1943', '361235', 'Ventimiglia', '', 'IT'),
        ('+39 10 012 4387'), 'i', 'ITALY', '700', 'Kevin.Cleveland@WILLET.COM',
        149);
INSERT INTO A_customers
VALUES (756, 'Kevin', 'Wilder', cust_address_typ
    ('Canale Grande 2', '361183', 'Roma', '', 'IT'),
        ('+39 6 012 4389'), 'i', 'ITALY', '700', 'Kevin.Wilder@AUKLET.COM',
        149);
INSERT INTO A_customers
VALUES (757, 'Kiefer', 'Reynolds', cust_address_typ
    ('Piazza Cacchiatore 23', '361184', 'Roma', '', 'IT'),
        ('+39 6 012 4391'), 'i', 'ITALY', '700', 'Kiefer.Reynolds@AVOCET.COM',
        149);
INSERT INTO A_customers
VALUES (766, 'Klaus', 'Young', cust_address_typ
    ('Via Del Disegno 194', '361223', 'San Giminiano', '', 'IT'),
        ('+39 49 012 4409'), 'i', 'ITALY', '600', 'Klaus.Young@OVENBIRD.COM',
        149);
INSERT INTO A_customers
VALUES (767, 'Klaus Maria', 'Russell', cust_address_typ
    ('Piazza Svizzera', '361221', 'San Giminiano', '', 'IT'),
        ('+39 49 012 4411'), 'i', 'ITALY', '100', 'KlausMaria.Russell@COOT.COM',
        NULL);
INSERT INTO A_customers
VALUES (768, 'Klaus Maria', 'MacLaine', cust_address_typ
    ('Via Dello Croce 93', '361227', 'Tellaro', '', 'IT'),
        ('+39 10 012 4413'), 'i', 'ITALY', '100', 'KlausMaria.MacLaine@CHUKAR.COM',
        149);
INSERT INTO A_customers
VALUES (769, 'Kris', 'Harris', cust_address_typ
    ('Via Dello Croce 93', '361217', 'San Giminiano', '', 'IT'),
        ('+39 49 012 4415'), 'i', 'ITALY', '400', 'Kris.Harris@DIPPER.COM',
        NULL);
INSERT INTO A_customers
VALUES (770, 'Kris', 'Curtis', cust_address_typ
    ('Ruella Delle Spiriti', '361222', 'San Giminiano', '', 'IT'),
        ('+39 49 012 4417'), 'i', 'ITALY', '400', 'Kris.Curtis@DOWITCHER.COM',
        NULL);
INSERT INTO A_customers
VALUES (771, 'Kris', 'de Niro', cust_address_typ
    ('Via Delle Capeletti 52', '361224', 'San Giminiano', '', 'IT'),
        ('+39 49 012 4419'), 'i', 'ITALY', '400', 'Kris.deNiro@DUNLIN.COM',
        NULL);
INSERT INTO A_customers
VALUES (772, 'Kristin', 'Savage', cust_address_typ
    ('Via Delli Capelli 2', '361226', 'Tellaro', '', 'IT'),
        ('+39 10 012 4421'), 'i', 'ITALY', '400', 'Kristin.Savage@CURLEW.COM',
        149);
INSERT INTO A_customers
VALUES (782, 'Laurence', 'Seignier', cust_address_typ
    ('1971 Limelight Blvd', '', 'Samutprakarn', '', 'TH'),
        ('+66 76 012 4441'), 'th', 'THAILAND', '1200', 'Laurence.Seignier@CREEPER.COM',
        149);
INSERT INTO A_customers
VALUES (825, 'Alain', 'Dreyfuss', cust_address_typ
    ('Harmoniegasse 3', '3413', 'Baden-Daettwil', 'AG', 'CH'),
        ('+41 56 012 3527'), 'd', 'SWITZERLAND', '500', 'Alain.Dreyfuss@VEERY.COM',
        149);
INSERT INTO A_customers
VALUES (826, 'Alain', 'Barkin', cust_address_typ
    ('Sonnenberg 4', '3413', 'Baden-Daettwil', 'AG', 'CH'),
        ('+41 57 012 3529'), 'd', 'SWITZERLAND', '500', 'Alain.Barkin@VERDIN.COM',
        149);
INSERT INTO A_customers
VALUES (827, 'Alain', 'Siegel', cust_address_typ
    ('Alfred E. Neumann-Weg 3', '3413', 'Baden-Daettwil', 'AG', 'CH'),
        ('+41 58 012 3531'), 'd', 'SWITZERLAND', '500', 'Alain.Siegel@VIREO.COM',
        149);
INSERT INTO A_customers
VALUES (828, 'Alan', 'Minnelli', cust_address_typ
    ('Dr. Herbert Bitto Str 23', '3413', 'Baden-Daettwil', 'AG', 'CH'),
        ('+41 59 012 3533'), 'd', 'SWITZERLAND', '2300',
        'Alan.Minnelli@TANAGER.COM',
        149);
INSERT INTO A_customers
VALUES (829, 'Alan', 'Hunter', cust_address_typ
    ('Taefernstr 4', '3413',
     'Baden-Daettwil', 'AG', 'CH'),
        ('+41 60 012 3535'), 'd', 'SWITZERLAND',
        '2300', 'Alan.Hunter@TATTLER.COM',
        149);
INSERT INTO A_customers
VALUES (830, 'Albert', 'Dutt', cust_address_typ
    ('Kreuzritterplatz 5', '3413', 'Baden-Daettwil', 'AG', 'CH'),
        ('+41 61 012 3537'), 'd', 'SWITZERLAND', '3500',
        'Albert.Dutt@CURLEW.COM',
        NULL);
INSERT INTO A_customers
VALUES (831, 'Albert', 'Bel Geddes', cust_address_typ
    ('Helebardenweg 5', '3413', 'Baden-Daettwil', 'AG', 'CH'),
        ('+41 62 012 3539'), 'd', 'SWITZERLAND', '3500',
        'Albert.BelGeddes@DIPPER.COM',
        NULL);
INSERT INTO A_customers
VALUES (832, 'Albert', 'Spacek', cust_address_typ
    ('Zum Freundlichen Nachbarn 5', '3413',
     'Baden-Daettwil', 'AG', 'CH'),
        ('+41 63 012 3541'), 'd', 'SWITZERLAND', '3500',
        'Albert.Spacek@DOWITCHER.COM',
        NULL);
INSERT INTO A_customers
VALUES (833, 'Alec', 'Moranis', cust_address_typ
    ('Ziegenwiese 3', '3413', 'Baden-Daettwil', 'AG', 'CH'),
        ('+41 64 012 3543'), 'd', 'SWITZERLAND', '3500',
        'Alec.Moranis@DUNLIN.COM',
        149);
INSERT INTO A_customers
VALUES (834, 'Alec', 'Idle', cust_address_typ
    ('Am Waldrand 5', '3413', 'Baden-Daettwil', 'AG', 'CH'),
        ('+41 65 012 3545'), 'd', 'SWITZERLAND', '3500',
        'Alec.Idle@EIDER.COM',
        NULL);
INSERT INTO A_customers
VALUES (835, 'Alexander', 'Eastwood', cust_address_typ
    ('Zur Kantine 9', '3413', 'Baden-Daettwil', 'AG', 'CH'),
        ('+41 66 012 3547'), 'd', 'SWITZERLAND', '1200',
        'Alexander.Eastwood@AVOCET.COM',
        149);
INSERT INTO A_customers
VALUES (836, 'Alexander', 'Berenger', cust_address_typ
    ('Grosse Bahnhostrasse 3', '3413', 'Baden-Daettwil', 'AG', 'CH'),
        ('+41 67 012 3549'), 'd', 'SWITZERLAND', '1200',
        'Alexander.Berenger@BECARD.COM',
        149);
INSERT INTO A_customers
VALUES (837, 'Alexander', 'Stanton', cust_address_typ
    ('Paradeplatz 4', '8001', 'Zuerich', 'ZH', 'CH'),
        ('+41 2 012 3551'), 'd', 'SWITZERLAND', '1200',
        'Alexander.Stanton@AUKLET.COM',
        149);
INSERT INTO A_customers
VALUES (838, 'Alfred', 'Nicholson', cust_address_typ
    ('Badenerstr 1941', '8004', 'Zuerich', 'ZH', 'CH'),
        ('+41 3 012 3553'), 'd', 'SWITZERLAND', '3500',
        'Alfred.Nicholson@CREEPER.COM',
        149);
INSERT INTO A_customers
VALUES (839, 'Alfred', 'Johnson', cust_address_typ
    ('Welschdoerfchen 1941', '7001', 'Chur', 'ZH', 'CH'),
        ('+41 81 012 3555'), 'd', 'SWITZERLAND', '3500', 'Alfred.Johnson@FLICKER.COM',
        149);
INSERT INTO A_customers
VALUES (840, 'Ali', 'Elliott', cust_address_typ
    ('Le Reduit', '7064', 'Tschiertschen', 'GR', 'CH'),
        ('+41 81 012 3557'), 'd', 'SWITZERLAND', '1400', 'Ali.Elliott@ANHINGA.COM',
        NULL);
INSERT INTO A_customers
VALUES (841, 'Ali', 'Boyer', cust_address_typ
    ('Bendlehn', '9062', 'Trogen', 'SG', 'CH'),
        ('+41 71 012 3559'), 'd', 'SWITZERLAND', '1400', 'Ali.Boyer@WILLET.COM',
        NULL);
INSERT INTO A_customers
VALUES (842, 'Ali', 'Stern', cust_address_typ
    ('Spisertor 3', '7000', 'St. Gallen', 'SG', 'CH'),
        ('+41 71 012 3561'), 'd', 'SWITZERLAND', '1400', 'Ali.Stern@YELLOWTHROAT.COM',
        149);
INSERT INTO A_customers
VALUES (843, 'Alice', 'Oates', cust_address_typ
    ('Langstr 14', '8004', 'Zuerich', 'ZH', 'CH'),
        ('+41 4 012 3563'), 'd', 'SWITZERLAND', '700', 'Alice.Oates@BECARD.COM',
        NULL);
INSERT INTO A_customers
VALUES (844, 'Alice', 'Julius', cust_address_typ
    ('Roessligasse 4', '8001', 'Zurich', 'ZH', 'CH'),
        ('+41 6 012 3565'), 'd', 'SWITZERLAND', '700', 'Alice.Julius@BITTERN.COM',
        NULL);
INSERT INTO A_customers
VALUES (845, 'Ally', 'Fawcett', cust_address_typ
    ('Zum Froehlichen Schweizer 3', '8000', 'Zurich', 'ZH', 'CH'),
        ('+41 7 012 3567'), 'd', 'SWITZERLAND', '5000',
        'Ally.Fawcett@PLOVER.COM',
        NULL);
INSERT INTO A_customers
VALUES (846, 'Ally', 'Brando', cust_address_typ
    ('Chrottenweg', '3000', 'Bern', 'BE', 'CH'),
        ('+41 31 012 3569'), 'd', 'SWITZERLAND', '5000',
        'Ally.Brando@PINTAIL.COM',
        149);
INSERT INTO A_customers
VALUES (847, 'Ally', 'Streep', cust_address_typ
    ('Bruppacher Str 3', '3413', 'Baden-Daettwil', 'AG', 'CH'),
        ('+41 68 012 3571'), 'd', 'SWITZERLAND', '5000',
        'Ally.Streep@PIPIT.COM',
        NULL);
INSERT INTO A_customers
VALUES (848, 'Alonso', 'Olmos', cust_address_typ
    ('Limmatquai', '8001', 'Zuerich', 'ZH', 'CH'),
        ('+41 5 012 3573'), 'd', 'SWITZERLAND', '1800',
        'Alonso.Olmos@PHALAROPE.COM',
        145);
INSERT INTO A_customers
VALUES (849, 'Alonso', 'Kaurusmdki', cust_address_typ
    ('Dreikoenigsstr 3', '8001', 'Zurich', 'ZH', 'CH'),
        ('+41 8 012 3575'), 'd', 'SWITZERLAND', '1800',
        'Alonso.Kaurusmdki@PHOEBE.COM',
        145);
INSERT INTO A_customers
VALUES (850, 'Amanda', 'Finney', cust_address_typ
    ('Pfannenstilstr 13', '8132', 'Egg', 'ZH', 'CH'),
        ('+41 1 012 3577'), 'd', 'SWITZERLAND', '2300',
        'Amanda.Finney@STILT.COM',
        145);
INSERT INTO A_customers
VALUES (851, 'Amanda', 'Brown', cust_address_typ
    ('Kreuzstr 32', '8032', 'Zurich', 'ZH', 'CH'),
        ('+41 9 012 3579'), 'd', 'SWITZERLAND', '2300',
        'Amanda.Brown@THRASHER.COM',
        145);
INSERT INTO A_customers
VALUES (852, 'Amanda', 'Tanner', cust_address_typ
    ('1539 Stripes Rd', '3413', 'Baden-Daettwil', 'AG', 'CH'),
        ('+41 69 012 3581'), 'd', 'SWITZERLAND', '2300',
        'Amanda.Tanner@TEAL.COM',
        145);
INSERT INTO A_customers
VALUES (853, 'Amrish', 'Palin', cust_address_typ
    ('1540 Stripes Crt', '3413', 'Baden-Daettwil', 'AG', 'CH'),
        ('+41 70 012 3583'), 'd', 'SWITZERLAND', '400', 'Amrish.Palin@EIDER.COM',
        145);
INSERT INTO A_customers
VALUES (905, 'Billy', 'Hershey', cust_address_typ
    ('1592 Silverado St', '361123', 'Bangalore', 'Kar', 'IN'),
        ('+91 80 012 3687'), 'hi', 'INDIA', '1400', 'Billy.Hershey@BULBUL.COM',
        NULL);
INSERT INTO A_customers
VALUES (906, 'Billy', 'Dench', cust_address_typ
    ('1593 Silverado St', '361112', 'Bangalore', 'Kar', 'IN'),
        ('+91 80 012 3689'), 'hi', 'INDIA', '1400', 'Billy.Dench@CARACARA.COM',
        149);
INSERT INTO A_customers
VALUES (909, 'Blake', 'Mastroianni', cust_address_typ
    ('1596 Commando Blvd', '361126', 'Bangalore', 'Kar', 'IN'),
        ('+91 80 012 3695'), 'hi', 'INDIA', '1200', 'Blake.Mastroianni@FLICKER.COM',
        149);
INSERT INTO A_customers
VALUES (911, 'Bo', 'Dickinson', cust_address_typ
    ('1598 Legend St', '361149', 'Bangalore', 'Kar', 'IN'),
        ('+91 80 012 3699'), 'hi', 'INDIA', '5000',
        'Bo.Dickinson@TANAGER.COM',
        149);
INSERT INTO A_customers
VALUES (912, 'Bo', 'Ashby', cust_address_typ
    ('1599 Legend Rd', '361128', 'Bangalore', 'Kar', 'IN'),
        ('+91 80 012 3701'), 'hi', 'INDIA', '5000',
        'Bo.Ashby@TATTLER.COM',
        NULL);
INSERT INTO A_customers
VALUES (913, 'Bob', 'Sharif', cust_address_typ
    ('1600 Target Crt', '361191', 'Bangalore', 'Kar', 'IN'),
        ('+91 80 012 3703'), 'hi', 'INDIA', '5000',
        'Bob.Sharif@TEAL.COM',
        NULL);
INSERT INTO A_customers
VALUES (916, 'Brian', 'Douglas', cust_address_typ
    ('1603 Rebel St', '361129', 'Bangalore', 'Kar', 'IN'),
        ('+91 80 012 3709'), 'hi', 'INDIA', '500', 'Brian.Douglas@AVOCET.COM',
        149);
INSERT INTO A_customers
VALUES (917, 'Brian', 'Baldwin', cust_address_typ
    ('1604 Volunteers Rd', '361121', 'Bangalore', 'Kar', 'IN'),
        ('+91 80 012 3711'), 'hi', 'INDIA', '500', 'Brian.Baldwin@BECARD.COM',
        149);
INSERT INTO A_customers
VALUES (919, 'Brooke', 'Michalkow', cust_address_typ
    ('1606 Volunteers Blvd', '361196', 'Bangalore', 'Kar', 'IN'),
        ('+91 80 012 3715'), 'hi', 'INDIA', '3500', 'Brooke.Michalkow@GROSBEAK.COM',
        NULL);
INSERT INTO A_customers
VALUES (920, 'Bruce', 'Hulce', cust_address_typ
    ('1607 Abwdrts St', '361114', 'Bangalore', 'Kar', 'IN'),
        ('+91 80 012 3717'), 'hi', 'INDIA', '3500', 'Bruce.Hulce@JACANA.COM',
        NULL);
INSERT INTO A_customers
VALUES (921, 'Bruce', 'Dunaway', cust_address_typ
    ('1608 Amadeus St', '361198', 'Bangalore', 'Kar', 'IN'),
        ('+91 80 012 3719'), 'hi', 'INDIA', '3500',
        'Bruce.Dunaway@JUNCO.COM',
        149);
INSERT INTO A_customers
VALUES (923, 'Bruno', 'Slater', cust_address_typ
    ('1610 Betrayal Crt', '361119', 'Bangalore', 'Kar', 'IN'),
        ('+91 80 012 3723'), 'hi', 'INDIA', '5000',
        'Bruno.Slater@THRASHER.COM',
        149);
INSERT INTO A_customers
VALUES (924, 'Bruno', 'Montand', cust_address_typ
    ('1611 Carmen Blvd', '361118', 'Bangalore', 'Kar', 'IN'),
        ('+91 80 012 3725'), 'hi', 'INDIA', '5000',
        'Bruno.Montand@TOWHEE.COM',
        149);
INSERT INTO A_customers
VALUES (927, 'Bryan', 'Belushi', cust_address_typ
    ('1614 Crackers Rd', '361168', 'Bangalore - India', 'Kar', 'IN'),
        ('+91 80 012 3731'), 'hi', 'INDIA', '2300',
        'Bryan.Belushi@TOWHEE.COM',
        149);
INSERT INTO A_customers
VALUES (928, 'Burt', 'Spielberg', cust_address_typ
    ('1615 Crackers Crt', '361168', 'Bangalore - India', 'Kar', 'IN'),
        ('+91 80 012 3733'), 'hi', 'INDIA', '5000',
        'Burt.Spielberg@TROGON.COM',
        NULL);
INSERT INTO A_customers
VALUES (929, 'Burt', 'Neeson', cust_address_typ
    ('1616 Crackers Blvd', '361168', 'Bangalore - India', 'Kar', 'IN'),
        ('+91 80 012 3735'), 'hi', 'INDIA', '5000',
        'Burt.Neeson@TURNSTONE.COM',
        149);
INSERT INTO A_customers
VALUES (930, 'Buster', 'Jackson', cust_address_typ
    ('1617 Crackers St', '361168', 'Bangalore - India', 'Kar', 'IN'),
        ('+91 80 012 3737'), 'hi', 'INDIA', '900', 'Buster.Jackson@KILLDEER.COM',
        149);
INSERT INTO A_customers
VALUES (931, 'Buster', 'Edwards', cust_address_typ
    ('1618 Footloose St', '361168', 'Bangalore - India', 'Kar', 'IN'),
        ('+91 80 012 3739'), 'hi', 'INDIA', '900', 'Buster.Edwards@KINGLET.COM',
        NULL);
INSERT INTO A_customers
VALUES (932, 'Buster', 'Bogart', cust_address_typ
    ('1619 Footloose Rd', '361168', 'Bangalore - India', 'Kar', 'IN'),
        ('+91 80 012 3741'), 'hi', 'INDIA', '900', 'Buster.Bogart@KISKADEE.COM',
        NULL);
INSERT INTO A_customers
VALUES (934, 'C. Thomas', 'Nolte', cust_address_typ
    ('1621 Gargon! Blvd', '361168', 'Bangalore - India', 'Kar', 'IN'),
        ('+91 80 012 3745'), 'hi', 'INDIA', '600', 'C.Thomas.Nolte@PHOEBE.COM',
        145);
INSERT INTO A_customers
VALUES (980, 'Daniel', 'Loren', cust_address_typ
    ('1667 2010 St', '61311', 'Batavia', 'IL', 'IN'),
        ('+91 80 012 3837'), 'hi', 'INDIA', '200', 'Daniel.Loren@REDSTART.COM',
        149);
INSERT INTO A_customers
VALUES (981, 'Daniel', 'Gueney', cust_address_typ
    ('1668 Chong Tao', '111181', 'Beijing', '', 'CN'),
        ('+86 10 012 3839'), 'zhs', 'CHINA', '200', 'Daniel.Gueney@REDPOLL.COM',
        149);

commit;

rem
rem Header: oe8_p_whs.sql 09-jan-01
rem
rem Copyright (c) 2001 Oracle Corporation.  All rights reserved.
rem
rem Owner  : ahunold
rem
rem NAME
rem   oe8_p_whs.sql - populate OE Common Schema
rem
rem DESCRIPTON
rem   Table A_warehouses
rem
rem MODIFIED   (MM/DD/YY)
rem   ahunold   10/
03/
01 - 8i

INSERT INTO A_warehouses
VALUES (1, 'Southlake, Texas', 1400);
INSERT INTO A_warehouses
VALUES (2, 'San Francisco', 1500);
INSERT INTO A_warehouses
VALUES (3, 'New Jersey', 1600);
INSERT INTO A_warehouses
VALUES (4, 'Seattle, Washington', 1700);
INSERT INTO A_warehouses
VALUES (5, 'Toronto', 1800);
INSERT INTO A_warehouses
VALUES (6, 'Sydney', 2200);
INSERT INTO A_warehouses
VALUES (7, 'Mexico City', 3200);
INSERT INTO A_warehouses
VALUES (8, 'Beijing', 2000);
INSERT INTO A_warehouses
VALUES (9, 'Bombay', 2100);

commit;

rem
rem Header: oe_p_pi.sql 09-jan01
rem
rem Copyright (c) 2001 Oracle Corporation.  All rights reserved.
rem
rem Owner  : ahunold
rem
rem NAME
rem   oe_p_pi.sql - populate OE Common Schema
rem
rem DESCRIPTON
rem   Table A_product_information
rem
rem MODIFIED   (MM/DD/YY)
rem   ahunold   04/
05/
01 - NULL prices for 3355,1770,1769
rem   ahunold   01/
09/
01 - checkin ADE


set define off
INSERT INTO A_product_information
VALUES ( 1726 -
       , 'LCD Monitor 11/PM' -
       , 'Liquid Cristal Display 11 inch passive monitor. The virtually-flat,-
high-resolution screen delivers outstanding image quality with reduced glare.'
       , 11, 3
       , to_number('00003')
       , 102067
       , 'under development'
       , 259
       , 208
       , 'http://www.www.supp-102067.com/cat/hw/p1726.html');
INSERT INTO A_product_information
VALUES ( 2359 -
       , 'LCD Monitor 9/PM' -
       , 'Liquid Cristal Display 9 inch passive monitor. Enjoy the productivity that-
a small monitor can bring via more workspace on your desk. Easy setup with-
plug-and-play compatibility.'
       , 11, 3
       , to_number('00003')
       , 102061
       , 'orderable'
       , 249
       , 206
       , 'http://www.www.supp-102061.com/cat/hw/p2359.html');
INSERT INTO A_product_information
VALUES ( 3060 -
       , 'Monitor 17/HR' -
       , 'CRT Monitor 17 inch (16 viewable) high resolution. Exceptional image-
performance and the benefit of additional screen space. This monitor offers-
sharp, color-rich monitor performance at an incredible value. With a host of-
leading features, including on-screen display controls.'
       , 11, 4
       , to_number('00006')
       , 102081
       , 'orderable'
       , 299
       , 250
       , 'http://www.supp-102081.com/cat/hw/p3060.html');
INSERT INTO A_product_information
VALUES ( 2243 -
       , 'Monitor 17/HR/F' -
       , 'Monitor 17 inch (16 viewable) high resolution, flat screen. High density-
photon gun with Enhanced Elliptical Correction System for more consistent,-
accurate focus across the screen, even in the corners.'
       , 11, 4
       , to_number('00006')
       , 102060
       , 'orderable'
       , 350
       , 302
       , 'http://www.supp-102060.com/cat/hw/p2243.html');
INSERT INTO A_product_information
VALUES ( 3057 -
       , 'Monitor 17/SD' -
       , 'CRT Monitor 17 inch (16 viewable) short depth. Delivers outstanding-
image clarity and precision. Gives professional color, technical-
engineering, and visualization/animation users the color fidelity they-
demand, plus a large desktop for enhanced productivity.'
       , 11, 4
       , to_number('00006')
       , 102055
       , 'orderable'
       , 369
       , 320
       , 'http://www.supp-102055.com/cat/hw/p3057.html');
INSERT INTO A_product_information
VALUES ( 3061 -
       , 'Monitor 19/SD' -
       , 'CRT Monitor 19 inch (18 viewable) short depth. High-contrast black-
screen coating: produces superior contrast and grayscale performance.-
The newly designed, amplified professional speakers with dynamic bass-
response bring all of your multimedia audio experiences to life with-
crisp, true-to-life sound and rich, deep bass tones. Plus, color-coded-
cables, simple plug-and-play setup and digital on-screen controls mean you-
are ready to set your sights on outrageous multimedia and the incredible-
Internet in just minutes.'
       , 11, 5
       , to_number('00009')
       , 102094
       , 'orderable'
       , 499
       , 437
       , 'http://www.supp-102094.com/cat/hw/p3061.html');
INSERT INTO A_product_information
VALUES ( 2245 -
       , 'Monitor 19/SD/M' -
       , 'Monitor 19 (18 Viewable) short depth, Monochrome. Outstanding image-
performance in a compact design. A simple, on-screen dislay menu helps you-
easily adjust screen dimensions, colors and image attributes. Just plug-
your monitor into your PC and you are ready to go.'
       , 11, 5
       , to_number('00009')
       , 102053
       , 'orderable'
       , 512
       , 420
       , 'http://www.supp-102053.com/cat/hw/p2245.html');
INSERT INTO A_product_information
VALUES ( 3065 -
       , 'Monitor 21/D' -
       , 'CRT Monitor 21 inch (20 viewable). Digital OptiScan technology: supports-
resolutions up to 1600 x 1200 at 75Hz. Dimensions (HxWxD): 8.3 x 18.5 x 15-
inch. The detachable or attachable monitor-powered Platinum Series speakers-
offer crisp sound and the convenience of a digital audio player jack. Just-
plug in your digital audio player and listen to tunes without powering up-
your PC.'
       , 11, 5
       , to_number('00100')
       , 102051
       , 'orderable'
       , 999
       , 875
       , 'http://www.supp-102051.com/cat/hw/p3065.html');
INSERT INTO A_product_information
VALUES ( 3331 -
       , 'Monitor 21/HR' -
       , '21 inch monitor (20 inch viewable) high resolution. This monitor is ideal-
for business, desktop publishing, and graphics-intensive applications. Enjoy-
the productivity that a large monitor can bring via more workspace for-
running applications.'
       , 11, 5
       , to_number('00100')
       , 102083
       , 'orderable'
       , 879
       , 785
       , 'http://www.supp-102083.com/cat/hw/p3331.html');
INSERT INTO A_product_information
VALUES ( 2252 -
       , 'Monitor 21/HR/M' -
       , 'Monitor 21 inch (20 viewable) high resolution, monochrome. Unit size:-
35.6 x 29.6 x 33.3 cm (14.6 kg) Package: 40.53 x 31.24 x 35.39 cm-
(16.5 kg). Horizontal frequency 31.5 - 54 kHz, Vertical frequency 50 - 120-
Hz. Universal power supply 90 - 132 V, 50 - 60 Hz.'
       , 11, 5
       , to_number('00106')
       , 102079
       , 'obsolete'
       , 889
       , 717
       , 'http://www.supp-102079.com/cat/hw/p2252.html');
INSERT INTO A_product_information
VALUES ( 3064 -
       , 'Monitor 21/SD' -
       , 'Monitor 21 inch (20 viewable) short depth. Features include a 0.250.28-
Aperture Grille Pitch, resolution support up to 1920 x 1200 at 76Hz,-
on-screen displays, and a conductive anti-reflective film coating.'
       , 11, 5
       , to_number('00106')
       , 102096
       , 'planned'
       , 1023
       , 909
       , 'http://www.supp-102096.com/cat/hw/p3064.html');
INSERT INTO A_product_information
VALUES ( 3155 -
       , 'Monitor Hinge - HD' -
       , 'Monitor Hinge, heavy duty, maximum monitor weight 30 kg'
       , 11, 4
       , to_number('01000')
       , 102092
       , 'orderable'
       , 49
       , 42
       , 'http://www.supp-102092.com/cat/hw/p3155.html');
INSERT INTO A_product_information
VALUES ( 3234 -
       , 'Monitor Hinge - STD' -
       , 'Standard Monitor Hinge, maximum monitor weight 10 kg'
       , 11, 3
       , to_number('01000')
       , 102072
       , 'orderable'
       , 39
       , 34
       , 'http://www.supp-102072.com/cat/hw/p3234.html');
INSERT INTO A_product_information
VALUES ( 3350 -
       , 'Plasma Monitor 10/LE/VGA' -
       , '10 inch low energy plasma monitor, VGA resolution'
       , 11, 3
       , to_number('00100')
       , 102068
       , 'orderable'
       , 740
       , 630
       , 'http://www.supp-102068.com/cat/hw/p3350.html');
INSERT INTO A_product_information
VALUES ( 2236 -
       , 'Plasma Monitor 10/TFT/XGA' -
       , '10 inch TFT XGA flatscreen monitor for laptop computers'
       , 11, 3
       , to_number('00100')
       , 102090
       , 'under development'
       , 964
       , 863
       , 'http://www.supp-102090.com/cat/hw/p2236.html');
INSERT INTO A_product_information
VALUES ( 3054 -
       , 'Plasma Monitor 10/XGA' -
       , '10 inch standard plasma monitor, XGA resolution. This virtually-flat,-
high-resolution screen delivers outstanding image quality with reduced glare.'
       , 11, 3
       , to_number('00100')
       , 102060
       , 'orderable'
       , 600
       , 519
       , 'http://www.supp-102060.com/cat/hw/p3054.html');
INSERT INTO A_product_information
VALUES ( 1782 -
       , 'Compact 400/DQ' -
       , '400 characters per second high-speed draft printer. Dimensions (HxWxD):-
17.34 x 24.26 x 26.32 inch. Interface: RS-232 serial (9-pin), no expansion-
slots. Paper size: A4, US Letter.'
       , 12, 4
       , to_number('00106')
       , 102088
       , 'obsolete'
       , 125
       , 108
       , 'http://www.supp-102088.com/cat/hw/p1782.html');
INSERT INTO A_product_information
VALUES ( 2430 -
       , 'Compact 400/LQ' -
       , '400 characters per second high-speed letter-quality printer.-
Dimensions (HxWxD): 12.37 x 27.96 x 23.92 inch. Interface: RS-232 serial-
(25-pin), 3 expansion slots. Paper size: A2, A3, A4.'
       , 12, 4
       , to_number('00200')
       , 102087
       , 'orderable'
       , 175
       , 143
       , 'http://www.supp-102087.com/cat/hw/p2430.html');
INSERT INTO A_product_information
VALUES ( 1792 -
       , 'Industrial 600/DQ' -
       , 'Wide carriage color capability 600 characters per second high-speed-
draft printer. Dimensions (HxWxD): 22.31 x 25.73 x 20.12 inch. Paper size:-
3x5 inch to 11x17 inch full bleed wide format.'
       , 12, 4
       , to_number('00500')
       , 102088
       , 'orderable'
       , 225
       , 180
       , 'http://www.supp-102088.com/cat/hw/p1792.html');
INSERT INTO A_product_information
VALUES ( 1791 -
       , 'Industrial 700/HD' -
       , '700 characters per second dot-matrix printer with harder body and dust-
protection for industrial uses. Interface: Centronics parallel, IEEE 1284-
compliant. Paper size: 3x5 inch to 11x17 inch full bleed wide format.-
Memory: 4MB. Dimensions (HxWxD): 9.3 x 16.5 x 13 inch.'
       , 12, 5
       , to_number('00500')
       , 102086
       , 'orderable'
       , 275
       , 239
       , 'http://www.supp-102086.com/cat/hw/p1791.html');
INSERT INTO A_product_information
VALUES ( 2302 -
       , 'Inkjet B/6' -
       , 'Inkjet Printer, black and white, 6 pages per minute, resolution 600x300-
dpi. Interface: Centronics parallel, IEEE 1284 compliant. Dimensions-
(HxWxD): 7.3 x 17.5 x 14 inch. Paper size: A3, A4, US legal. No-
expansion slots.'
       , 12, 3
       , to_number('00200')
       , 102096
       , 'orderable'
       , 150
       , 121
       , 'http://www.supp-102096.com/cat/hw/p2302.html');
INSERT INTO A_product_information
VALUES ( 2453 -
       , 'Inkjet C/4' -
       , 'Inkjet Printer, color (with two separate ink cartridges), 6 pages per-
minute black and white, 4 pages per minute color, resolution 600x300 dpi.-
Interface: Biodirectional IEEE 1284 compliant parallel interface and-
RS-232 serial (9-pin) interface 2 open EIO expansion slots. Memory:-
8MB 96KB receiver buffer.'
       , 12, 3
       , to_number('00200')
       , 102090
       , 'orderable'
       , 195
       , 174
       , 'http://www.supp-102090.com/cat/hw/p2453.html');
INSERT INTO A_product_information
VALUES ( 1797 -
       , 'Inkjet C/8/HQ' -
       , 'Inkjet printer, color, 8 pages per minute, high resolution (photo-
quality). Memory: 16MB. Dimensions (HxWxD): 7.3 x 17.5 x 14 inch. Paper-
size: A4, US Letter, envelopes. Interface: Centronics parallel, IEEE-
1284 compliant.'
       , 12, 3
       , to_number('00200')
       , 102094
       , 'orderable'
       , 349
       , 288
       , 'http://www.supp-102094.com/cat/hw/p1797.html');
INSERT INTO A_product_information
VALUES ( 2459 -
       , 'LaserPro 1200/8/BW' -
       , 'Professional black and white laserprinter, resolution 1200 dpi, 8 pages-
per second. Dimensions (HxWxD): 22.37 x 19.86 x 21.92 inch. Software:-
Enhanced driver support for SPNIX v4.0; MS-DOS Built-in printer drivers:-
ZoomSmart scaling technology, billboard, handout, mirror, watermark, print-
preview, quick sets, emulate laserprinter margins.'
       , 12, 5
       , to_number('00300')
       , 102099
       , 'under development'
       , 699
       , 568
       , 'http://www.supp-102099.com/cat/hw/p2459.html');
INSERT INTO A_product_information
VALUES ( 3127 -
       , 'LaserPro 600/6/BW' -
       , 'Standard black and white laserprinter, resolution 600 dpi, 6 pages per-
second. Interface: Centronics parallel, IEEE 1284 compliant. Memory: 8MB-
96KB receiver buffer. MS-DOS ToolBox utilities for SPNIX AutoCAM v.17-
compatible driver.'
       , 12, 4
       , to_number('00300')
       , 102087
       , 'orderable'
       , 498
       , 444
       , 'http://www.supp-102087.com/cat/hw/p3127.html');
INSERT INTO A_product_information
VALUES ( 2254 -
       , 'HD 10GB /I' -
       , '10GB capacity hard disk drive (internal). These drives are intended for-
use in today''s demanding, data-critical enterprise environments and are-
ideal for use in RAID applications. Universal option kits are configured-
and pre-mounted in the appropriate hot plug tray for immediate installation-
into your corporate server or storage system.'
       , 13, 2
       , to_number('00200')
       , 102071
       , 'obsolete'
       , 453
       , 371
       , 'http://www.supp-102071.com/cat/hw/p2254.html');
INSERT INTO A_product_information
VALUES ( 3353 -
       , 'HD 10GB /R' -
       , '10GB Removable hard disk drive for 10GB Removable HD drive. Supra7-
disk drives provide the latest technology to improve enterprise-
performance, increasing the maximum data transfer rate up to 160MB/s.'
       , 13, 1
       , to_number('00300')
       , 102071
       , 'obsolete'
       , 489
       , 413
       , 'http://www.supp-102071.com/cat/hw/p3353.html');
INSERT INTO A_product_information
VALUES ( 3069 -
       , 'HD 10GB /S' -
       , '10GB hard disk drive for Standard Mount. Backward compatible with-
Supra5 systems, users are free to deploy and re-deploy these drives to-
quickly deliver increased storage capacity. Supra drives eliminate the-
risk of firmware incompatibility.'
       , 13, 1
       , to_number('00200')
       , 102051
       , 'obsolete'
       , 436
       , 350
       , 'http://www.supp-102051.com/cat/hw/p3069.html');
INSERT INTO A_product_information
VALUES ( 2253 -
       , 'HD 10GB @5400 /SE' -
       , '10GB capacity hard disk drive (external) SCSI interface, 5400 RPM.-
Universal option kits are configured and pre-mounted in the appropriate-
hot plug tray for immediate installation into your corporate server or-
storage system. Supra drives eliminate the risk of firmware incompatibility.'
       , 13, 2
       , to_number('00300')
       , 102069
       , 'obsolete'
       , 399
       , 322
       , 'http://www.supp-102069.com/cat/hw/p2253.html');
INSERT INTO A_product_information
VALUES ( 3354 -
       , 'HD 12GB /I' -
       , '12GB capacity harddisk drive (internal). Supra drives eliminate the risk-
of firmware incompatibility. Backward compatibility: You can mix or-
match Supra2 and Supra3 devices for optimized solutions and future growth.'
       , 13, 2
       , to_number('00200')
       , 102066
       , 'orderable'
       , 543
       , 478
       , 'http://www.supp-102066.com/cat/hw/p3354.html');
INSERT INTO A_product_information
VALUES ( 3072 -
       , 'HD 12GB /N' -
       , '12GB hard disk drive for Narrow Mount. Supra9 hot pluggable hard disk-
drives provide the ability to install or remove drives on-line. Our hot-
pluggable hard disk drives are required to meet our rigorous standards-
for reliability and performance.'
       , 13, 1
       , to_number('00300')
       , 102061
       , 'orderable'
       , 567
       , 507
       , 'http://www.supp-102061.com/cat/hw/p3072.html');
INSERT INTO A_product_information
VALUES ( 3334 -
       , 'HD 12GB /R' -
       , '12GB Removable hard disk drive. With compatibility across many enterprise-
platforms, you are free to deploy and re-deploy this drive to quickly-
deliver increased storage capacity. Supra7 Universal disk drives are the-
second generation of high performance hot plug drives sharing compatibility-
across corporate servers and external storage enclosures.'
       , 13, 2
       , to_number('00300')
       , 102090
       , 'orderable'
       , 612
       , 512
       , 'http://www.supp-102090.com/cat/hw/p3334.html');
INSERT INTO A_product_information
VALUES ( 3071 -
       , 'HD 12GB /S' -
       , '12GB hard disk drive for Standard Mount. Supra9 hot pluggable hard disk-
drives provide the ability to install or remove drives on-line. Our hot-
pluggable hard disk drives are required to meet our rigorous standards-
for reliability and performance.'
       , 13, 1
       , to_number('00300')
       , 102071
       , 'orderable'
       , 633
       , 553
       , 'http://www.supp-102071.com/cat/hw/p3071.html');
INSERT INTO A_product_information
VALUES ( 2255 -
       , 'HD 12GB @7200 /SE' -
       , '12GB capacity hard disk drive (external) SCSI, 7200 RPM. These drives-
are intended for use in today''s demanding, data-critical enterprise-
environments and can be used in RAID applications. Universal option kits-
are configured and pre-mounted in the appropriate hot plug tray for-
immediate installation into your corporate server or storage system.'
       , 13, 2
       , to_number('00200')
       , 102057
       , 'orderable'
       , 775
       , 628
       , 'http://www.supp-102057.com/cat/hw/p2255.html');
INSERT INTO A_product_information
VALUES ( 1743 -
       , 'HD 18.2GB @10000 /E' -
       , 'External hard drive disk - 18.2 GB, rated up to 10,000 RPM. These-
drives are intended for use in today''s demanding, data-critical-
enterprise environments and are ideal for use in RAID applications.'
       , 13, 3
       , to_number('00300')
       , 102078
       , 'planned'
       , 800
       , 661
       , 'http://www.supp-102078.com/cat/hw/p1743.html');
INSERT INTO A_product_information
VALUES ( 2382 -
       , 'HD 18.2GB@10000 /I' -
       , '18.2 GB SCSI hard disk @ 10000 RPM (internal). Supra7 Universal-
disk drives provide an unequaled level of investment protection and-
simplification for customers by enabling drive compatibility across-
many enterprise platforms.'
       , 13, 3
       , to_number('00300')
       , 102050
       , 'under development'
       , 850
       , 731
       , 'http://www.supp-102050.com/cat/hw/p2382.html');
INSERT INTO A_product_information
VALUES ( 3399 -
       , 'HD 18GB /SE' -
       , '18GB SCSI external hard disk drive. Supra5 Universal hard disk-
drives provide the ability to hot plug between various servers, RAID-
arrays, and external storage shelves.'
       , 13, 3
       , to_number('00200')
       , 102083
       , 'under development'
       , 815
       , 706
       , 'http://www.supp-999999.com/cat/hw/p3333.html');
INSERT INTO A_product_information
VALUES ( 3073 -
       , 'HD 6GB /I' -
       , '6GB capacity hard disk drive (internal). Supra drives eliminate the-
risk of firmware incompatibility.'
       , 13, 2
       , to_number('00500')
       , 102072
       , 'obsolete'
       , 224
       , 197
       , 'http://www.supp-102083.com/cat/hw/p3073.html');
INSERT INTO A_product_information
VALUES ( 1768 -
       , 'HD 8.2GB @5400' -
       , 'Hard drive disk - 8.2 GB, rated up to 5,400 RPM. Supra drives-
eliminate the risk of firmware incompatibility. Standard serial-
RS-232 interface.'
       , 13, 2
       , to_number('00200')
       , 102093
       , 'orderable'
       , 345
       , 306
       , 'http://www.supp-102093.com/cat/hw/p1768.html');
INSERT INTO A_product_information
VALUES ( 2410 -
       , 'HD 8.4GB @5400' -
       , '8.4 GB hard disk @ 5400 RPM. Reduced cost of ownership: Drives can-
be utilized across enterprise platforms. This hot pluggable hard disk-
drive is required to meet your rigorous standards for reliability-
and performance.'
       , 13, 2
       , to_number('00300')
       , 102061
       , 'orderable'
       , 357
       , 319
       , 'http://www.supp-102061.com/cat/hw/p2410.html');
INSERT INTO A_product_information
VALUES ( 2257 -
       , 'HD 8GB /I' -
       , '8GB capacity hard disk drive (internal). Supra9 hot pluggable-
hard disk drives provide the ability to install or remove drives-
on-line. Backward compatibility: You can mix Supra2 and Supra3-
devices for optimized solutions and future growth.'
       , 13, 1
       , to_number('00300')
       , 102061
       , 'orderable'
       , 399
       , 338
       , 'http://www.supp-102061.com/cat/hw/p2257.html');
INSERT INTO A_product_information
VALUES ( 3400 -
       , 'HD 8GB /SE' -
       , '8GB capacity SCSI hard disk drive (external). Supra7 disk drives-
provide the latest technology to improve enterprise performance,-
increasing the maximum data transfer rate up to 255MB/s.'
       , 13, 2
       , to_number('00300')
       , 102063
       , 'orderable'
       , 389
       , 337
       , 'http://www.supp-102063.com/cat/hw/p3400.html');
INSERT INTO A_product_information
VALUES ( 3355 -
       , 'HD 8GB /SI' -
       , '8GB SCSI hard disk drive, internal. With compatibility across many-
enterprise platforms, you are free to deploy and re-deploy this drive-
to quickly deliver increased storage capacity. '
       , 13, 1
       , to_number('00200')
       , 102050
       , 'orderable'
       , NULL
       , NULL
       , 'http://www.supp-102050.com/cat/hw/p3355.html');
INSERT INTO A_product_information
VALUES ( 1772 -
       , 'HD 9.1GB @10000' -
       , 'Hard disk drive - 9.1 GB, rated up to 10,000 RPM. These drives-
are intended for use in data-critical enterprise environments.-
Ease of doing business: you can easily select the drives you need-
regardless of the application in which they will be deployed.'
       , 13, 3
       , to_number('00500')
       , 102070
       , 'orderable'
       , 456
       , 393
       , 'http://www.supp-102070.com/cat/hw/p1772.html');
INSERT INTO A_product_information
VALUES ( 2414 -
       , 'HD 9.1GB @10000 /I' -
       , '9.1 GB SCSI hard disk @ 10000 RPM (internal). Supra7 disk-
drives are available in 10,000 RPM spindle speeds and capacities-
of 18GB and 9.1 GB. SCSI and RS-232 interfaces.'
       , 13, 3
       , to_number('00500')
       , 102098
       , 'orderable'
       , 454
       , 399
       , 'http://www.supp-102098.com/cat/hw/p2414.html');
INSERT INTO A_product_information
VALUES ( 2415 -
       , 'HD 9.1GB @7200' -
       , '9.1 GB hard disk @ 7200 RPM. Universal option kits are-
configured and pre-mounted in the appropriate hot plug tray-
for immediate installation into your corporate server or storage-
system.'
       , 13, 3
       , to_number('00500')
       , 102063
       , 'orderable'
       , 359
       , 309
       , 'http://www.supp-102063.com/cat/hw/p2415.html');
INSERT INTO A_product_information
VALUES ( 2395 -
       , '32MB Cache /M' -
       , '32MB Mirrored cache memory (100-MHz Registered SDRAM)'
       , 14, 1
       , to_number('00006')
       , 102093
       , 'orderable'
       , 123
       , 109
       , 'http://www.supp-102093.com/cat/hw/p2395.html');
INSERT INTO A_product_information
VALUES ( 1755 -
       , '32MB Cache /NM' -
       , '32MB Non-Mirrored cache memory'
       , 14, 1
       , to_number('00006')
       , 102076
       , 'orderable'
       , 121
       , 99
       , 'http://www.supp-102076.com/cat/hw/p1755.html');
INSERT INTO A_product_information
VALUES ( 2406 -
       , '64MB Cache /M' -
       , '64MB Mirrored cache memory'
       , 14, 1
       , to_number('00006')
       , 102059
       , 'orderable'
       , 223
       , 178
       , 'http://www.supp-102059.com/cat/hw/p2406.html');
INSERT INTO A_product_information
VALUES ( 2404 -
       , '64MB Cache /NM' -
       , '64 MB Non-mirrored cache memory. FPM memory chips are-
implemented on 5 volt SIMMs, but are also available on-
3.3 volt DIMMs.'
       , 14, 1
       , to_number('00006')
       , 102087
       , 'orderable'
       , 221
       , 180
       , 'http://www.supp-102087.com/cat/hw/p2404.html');
INSERT INTO A_product_information
VALUES ( 1770 -
       , '8MB Cache /NM' -
       , '8MB Non-Mirrored Cache Memory (100-MHz Registered SDRAM)'
       , 14, 1
       , to_number('00006')
       , 102050
       , 'orderable'
       , NULL
       , 73
       , 'http://www.supp-102050.com/cat/hw/p1770.html');
INSERT INTO A_product_information
VALUES ( 2412 -
       , '8MB EDO Memory' -
       , '8 MB 8x32 EDO SIM memory. Extended Data Out memory differs from FPM in a-
small, but significant design change. Unlike FPM, the data output drivers-
for EDO remain on when the memory controller removes the column address to-
begin the next cycle. Therefore, a new data cycle can begin before the-
previous cycle has completed. EDO is available on SIMMs and DIMMs, in 3.3-
and 5 volt varieties.'
       , 14, 1
       , to_number('00006')
       , 102058
       , 'obsolete'
       , 98
       , 83
       , 'http://www.supp-102058.com/cat/hw/p2412.html');
INSERT INTO A_product_information
VALUES ( 2378 -
       , 'DIMM - 128 MB' -
       , '128 MB DIMM memory. The main reason for the change from SIMMs to DIMMs is-
to support the higher bus widths of 64-bit processors. DIMMs are 64- or-
72-bits wide; SIMMs are only 32- or 36-bits wide (with parity).'
       , 14, 1
       , to_number('00006')
       , 102050
       , 'orderable'
       , 305
       , 247
       , 'http://www.supp-102050.com/cat/hw/p2378.html');
INSERT INTO A_product_information
VALUES ( 3087 -
       , 'DIMM - 16 MB' -
       , 'Citrus OLX DIMM - 16 MB capacity.'
       , 14, 1
       , to_number('00006')
       , 102081
       , 'obsolete'
       , 124
       , 99
       , 'http://www.supp-102081.com/cat/hw/p3087.html');
INSERT INTO A_product_information
VALUES ( 2384 -
       , 'DIMM - 1GB' -
       , 'Memory DIMM: RAM - 1 GB capacity.'
       , 14, 1
       , to_number('00006')
       , 102074
       , 'under development'
       , 599
       , 479
       , 'http://www.supp-102074.com/cat/hw/p2384.html');
INSERT INTO A_product_information
VALUES ( 1749 -
       , 'DIMM - 256MB' -
       , 'Memory DIMM: RAM 256 MB. (100-MHz Registered SDRAM)'
       , 14, 1
       , to_number('00006')
       , 102053
       , 'orderable'
       , 337
       , 300
       , 'http://www.supp-102053.com/cat/hw/p1749.html');
INSERT INTO A_product_information
VALUES ( 1750 -
       , 'DIMM - 2GB' -
       , 'Memory DIMM: RAM, 2 GB capacity.'
       , 14, 1
       , to_number('00006')
       , 102052
       , 'orderable'
       , 699
       , 560
       , 'http://www.supp-102052.com/cat/hw/p1750.html');
INSERT INTO A_product_information
VALUES ( 2394 -
       , 'DIMM - 32MB' -
       , '32 MB DIMM Memory upgrade'
       , 14, 1
       , to_number('00006')
       , 102054
       , 'orderable'
       , 128
       , 106
       , 'http://www.supp-102054.com/cat/hw/p2394.html');
INSERT INTO A_product_information
VALUES ( 2400 -
       , 'DIMM - 512 MB' -
       , '512 MB DIMM memory. Improved memory upgrade granularity: Fewer DIMMs are-
required to upgrade a system than it would require if using SIMMs in the same-
system. Increased maximum memory ceilings: Given the same number of memory-
slots, the maximum memory of a system using DIMMs is more than one using-
SIMMs. DIMMs have separate contacts on each side of the board, which provide-
two times the data rate as one SIMM.'
       , 14, 1
       , to_number('00100')
       , 102098
       , 'under development'
       , 448
       , 380
       , 'http://www.supp-102098.com/cat/hw/p2400.html');
INSERT INTO A_product_information
VALUES ( 1763 -
       , 'DIMM - 64MB' -
       , 'Memory DIMM: RAM, 64MB (100-MHz Unregistered ECC SDRAM)'
       , 14, 1
       , to_number('00100')
       , 102069
       , 'orderable'
       , 247
       , 202
       , 'http://www.supp-102069.com/cat/hw/p1763.html');
INSERT INTO A_product_information
VALUES ( 2396 -
       , 'EDO - 32MB' -
       , 'Memory EDO SIM: RAM, 32 MB (100-MHz Unregistered ECC SDRAM). Like FPM,-
EDO is available on SIMMs and DIMMs, in 3.3 and 5 volt varieties If EDO-
memory is installed in a computer that was not designed to support it,-
the memory may not work.'
       , 14, 1
       , to_number('00006')
       , 102051
       , 'orderable'
       , 179
       , 149
       , 'http://www.supp-102051.com/cat/hw/p2396.html');
INSERT INTO A_product_information
VALUES ( 2272 -
       , 'RAM - 16 MB' -
       , 'Memory SIMM: RAM - 16 MB capacity.'
       , 14, 1
       , to_number('00100')
       , 102074
       , 'obsolete'
       , 135
       , 110
       , 'http://www.supp-102074.com/cat/hw/p2272.html');
INSERT INTO A_product_information
VALUES ( 2274 -
       , 'RAM - 32 MB' -
       , 'Memory SIMM: RAM - 32 MB capacity.'
       , 14, 1
       , to_number('00100')
       , 102064
       , 'orderable'
       , 161
       , 135
       , 'http://www.supp-102064.com/cat/hw/p2274.html');
INSERT INTO A_product_information
VALUES ( 3090 -
       , 'RAM - 48 MB' -
       , 'Random Access Memory, SIMM - 48 MB capacity.'
       , 14, 1
       , to_number('00100')
       , 102084
       , 'orderable'
       , 193
       , 170
       , 'http://www.supp-102084.com/cat/hw/p3090.html');
INSERT INTO A_product_information
VALUES ( 1739 -
       , 'SDRAM - 128 MB' -
       , 'SDRAM memory, 128 MB capacity. SDRAM can access data at speeds up to 100-
MHz, which is up to four times as fast as standard DRAMs. The advantages of-
SDRAM can be fully realized, however, only by computers designed to support-
SDRAM. SDRAM is available on 5 and 3.3 volt DIMMs.'
       , 14, 1
       , to_number('00009')
       , 102077
       , 'orderable'
       , 299
       , 248
       , 'http://www.supp-102077.com/cat/hw/p1739.html');
INSERT INTO A_product_information
VALUES ( 3359 -
       , 'SDRAM - 16 MB' -
       , 'SDRAM memory upgrade module, 16 MB. Synchronous Dynamic Random Access-
Memory was introduced after EDO. Its architecture and operation are based on-
those of the standard DRAM, but SDRAM provides a revolutionary change to main-
memory that further reduces data retrieval times. SDRAM is synchronized to-
the system clock that controls the CPU. This means that the system clock-
controlling the functions of the microprocessor also controls the SDRAM-
functions. This enables the memory controller to know on which clock cycle-
a data request will be ready, and therefore eliminates timing delays.'
       , 14, 1
       , to_number('00009')
       , 102059
       , 'orderable'
       , 111
       , 99
       , 'http://www.supp-102059.com/cat/hw/p3359.html');
INSERT INTO A_product_information
VALUES ( 3088 -
       , 'SDRAM - 32 MB' -
       , 'SDRAM module with ECC - 32 MB capacity. SDRAM has multiple memory banks-
that can work simultaneously. Switching between banks allows for a-
continuous data flow.'
       , 14, 1
       , to_number('00009')
       , 102057
       , 'orderable'
       , 258
       , 220
       , 'http://www.supp-102057.com/cat/hw/p3088.html');
INSERT INTO A_product_information
VALUES ( 2276 -
       , 'SDRAM - 48 MB' -
       , 'Memory SIMM: RAM - 48 MB. SDRAM can operate in burst mode. In burst-
mode, when a single data address is accessed, an entire block of data is-
retrieved rather than just the one piece. The assumption is that the next-
piece of data that will be requested will be sequential to the previous.-
Since this is usually the case, data is held readily available.'
       , 14, 1
       , to_number('00009')
       , 102058
       , 'orderable'
       , 269
       , 215
       , 'http://www.supp-102058.com/cat/hw/p2276.html');
INSERT INTO A_product_information
VALUES ( 3086 -
       , 'VRAM - 16 MB' -
       , 'Citrus Video RAM module - 16 MB capacity. VRAM is used by the video system-
in a computer to store video information and is reserved exclusively for-
video operations. It was developed to provide continuous streams of serial-
data for refreshing video screens.'
       , 14, 1
       , to_number('00006')
       , 102056
       , 'orderable'
       , 211
       , 186
       , 'http://www.supp-102056.com/cat/hw/p3086.html');
INSERT INTO A_product_information
VALUES ( 3091 -
       , 'VRAM - 64 MB' -
       , 'Citrus Video RAM memory module - 64 MB capacity. Physically, VRAM looks-
just like DRAM with added hardware called a shift register. The special-
feature of VRAM is that it can transfer one entire row of data (up to 256-
bits) into this shift register in a single clock cycle. This ability-
significantly reduces retrieval time, since the number of fetches is reduced-
from a possible 256 to a single fetch. The main benefit of having a shift-
register available for data dumps is that it frees the CPU to refresh the-
screen rather than retrieve data, thereby doubling the data bandwidth. For-
this reason, VRAM is often referred to as being dual-ported. However, the-
shift register will only be used when the VRAM chip is given special-
instructions to do so. The command to use the shift register is built into-
the graphics controller.'
       , 14, 1
       , to_number('00006')
       , 102098
       , 'orderable'
       , 279
       , 243
       , 'http://www.supp-102098.com/cat/hw/p3091.html');
INSERT INTO A_product_information
VALUES ( 1787 -
       , 'CPU D300' -
       , 'Dual CPU @ 300Mhz. For light personal processing only, or file servers-
with less than 5 concurrent users. This product will probably become-
obsolete soon.'
       , 15, 1
       , to_number('00300')
       , 102097
       , 'orderable'
       , 101
       , 90
       , 'http://www.supp-102097.com/cat/hw/p1787.html');
INSERT INTO A_product_information
VALUES ( 2439 -
       , 'CPU D400' -
       , 'Dual CPU @ 400Mhz. Good price/performance ratio; for mid-size LAN-
file servers (up to 100 concurrent users).'
       , 15, 1
       , to_number('00300')
       , 102092
       , 'orderable'
       , 123
       , 105
       , 'http://www.supp-102092.com/cat/hw/p2439.html');
INSERT INTO A_product_information
VALUES ( 1788 -
       , 'CPU D600' -
       , 'Dual CPU @ 600Mhz. State of the art, high clock speed; for heavy-
load WAN servers (up to 200 concurrent users).'
       , 15, 1
       , to_number('00500')
       , 102067
       , 'orderable'
       , 178
       , 149
       , 'http://www.supp-102067.com/cat/hw/p1788.html');
INSERT INTO A_product_information
VALUES ( 2375 -
       , 'GP 1024x768' -
       , 'Graphics Processor, resolution 1024 X 768 pixels. Outstanding-
price/performance for 2D and 3D applications under SPNIX v3.3 and-
v4.0. Double your viewing power by running two monitors from this-
single card. Two 17 inch monitors have more screen area than one-
21 inch monitor. Excellent option for users that multi-task-
frequently or access data from multiple sources often.'
       , 15, 1
       , to_number('00009')
       , 102063
       , 'orderable'
       , 78
       , 69
       , 'http://www.supp-102063.com/cat/hw/p2375.html');
INSERT INTO A_product_information
VALUES ( 2411 -
       , 'GP 1280x1024' -
       , 'Graphics Processor, resolution 1280 X 1024 pixels. High end 3D performance-
at a mid range price: 15 million Gouraud shaded triangles per second,-
Optimized 3D drivers for MCAD and DCC applications, with user-customizable-
settings. 64MB DDR SDRAM unified frame buffer supporting true color at all-
supported standard resolutions.'
       , 15, 1
       , to_number('00100')
       , 102061
       , 'orderable'
       , 98
       , 78
       , 'http://www.supp-102061.com/cat/hw/p2411.html');
INSERT INTO A_product_information
VALUES ( 1769 -
       , 'GP 800x600' -
       , 'Graphics processor, resolution 800 x 600 pixels. Remarkable value for-
users requiring great 2D capabilities or general 3D support for advanced-
applications. Drives incredible performance in highly complex models and-
frees the customer to focus on the design, instead of the rendering process.'
       , 15, 1
       , to_number('00006')
       , 102050
       , 'orderable'
       , 48
       , NULL
       , 'http://www.supp-102050.com/cat/hw/p1769.html');
INSERT INTO A_product_information
VALUES ( 2049 -
       , 'MB - S300' -
       , 'PC type motherboard, 300 Series.'
       , 15, 2
       , to_number('00100')
       , 102082
       , 'obsolete'
       , 55
       , 47
       , 'http://www.supp-102082.com/cat/hw/p2049.html');
INSERT INTO A_product_information
VALUES ( 2751 -
       , 'MB - S450' -
       , 'PC type motherboard, 450 Series.'
       , 15, 2
       , to_number('00100')
       , 102072
       , 'orderable'
       , 66
       , 54
       , 'http://www.supp-102072.com/cat/hw/p2751.html');
INSERT INTO A_product_information
VALUES ( 3112 -
       , 'MB - S500' -
       , 'PC type motherboard, 500 Series.'
       , 15, 2
       , to_number('00106')
       , 102086
       , 'orderable'
       , 77
       , 66
       , 'http://www.supp-102086.com/cat/hw/p3112.html');
INSERT INTO A_product_information
VALUES ( 2752 -
       , 'MB - S550' -
       , 'PC type motherboard for the 550 Series.'
       , 15, 2
       , to_number('00106')
       , 102086
       , 'orderable'
       , 88
       , 76
       , 'http://www.supp-102086.com/cat/hw/p2752.html');
INSERT INTO A_product_information
VALUES ( 2293 -
       , 'MB - S600' -
       , 'Motherboard, 600 Series.'
       , 15, 2
       , to_number('00200')
       , 102086
       , 'orderable'
       , 99
       , 87
       , 'http://www.supp-102086.com/cat/hw/p2293.html');
INSERT INTO A_product_information
VALUES ( 3114 -
       , 'MB - S900/6500' -
       , 'PC motherboard, 900 Series; standard motherboard-
for all models 650 and up.'
       , 15, 3
       , to_number('00000')
       , 102086
       , 'under development'
       , 101
       , 88
       , 'http://www.supp-102086.com/cat/hw/p3114.html');
INSERT INTO A_product_information
VALUES ( 3129 -
       , 'Sound Card STD' -
       , 'Sound Card - standard version, with MIDI interface,-
line in/out, low impedance microphone input.'
       , 15, 1
       , to_number('00006')
       , 102090
       , 'orderable'
       , 46
       , 39
       , 'http://www.supp-102090.com/cat/hw/p3129.html');
INSERT INTO A_product_information
VALUES ( 3133 -
       , 'Video Card /32' -
       , 'Video Card, with 32MB cache memory.'
       , 15, 2
       , to_number('00006')
       , 102076
       , 'orderable'
       , 48
       , 41
       , 'http://www.supp-102076.com/cat/hw/p3133.html');
INSERT INTO A_product_information
VALUES ( 2308 -
       , 'Video Card /E32' -
       , '3-D ELSA Video Card, with 32 MB memory.'
       , 15, 2
       , to_number('00006')
       , 102087
       , 'orderable'
       , 58
       , 48
       , 'http://www.supp-102087.com/cat/hw/p2308.html');
INSERT INTO A_product_information
VALUES ( 2496 -
       , 'WSP DA-130' -
       , 'Wide storage processor DA-130 for storage subunits.'
       , 15, 2
       , to_number('00000')
       , 102067
       , 'planned'
       , 299
       , 244
       , 'http://www.supp-102067.com/cat/hw/p2496.html');
INSERT INTO A_product_information
VALUES ( 2497 -
       , 'WSP DA-290' -
       , 'Wide storage processor (model DA-290).'
       , 15, 3
       , to_number('00000')
       , 102053
       , 'planned'
       , 399
       , 355
       , 'http://www.supp-102053.com/cat/hw/p2497.html');
INSERT INTO A_product_information
VALUES ( 3106 -
       , 'KB 101/EN' -
       , 'Standard PC/AT Enhanced Keyboard (101/102-Key).-
Input locale: English (US).'
       , 16, 1
       , to_number('00100')
       , 102066
       , 'orderable'
       , 48
       , 41
       , 'http://www.supp-102066.com/cat/hw/p3106.html');
INSERT INTO A_product_information
VALUES ( 2289 -
       , 'KB 101/ES' -
       , 'Standard PC/AT Enhanced Keyboard (101/102-Key).-
Input locale: Spanish.'
       , 16, 1
       , to_number('00100')
       , 102055
       , 'orderable'
       , 48
       , 38
       , 'http://www.supp-102055.com/cat/hw/p2289.html');
INSERT INTO A_product_information
VALUES ( 3110 -
       , 'KB 101/FR' -
       , 'Standard PC/AT Enhanced Keyboard (101/102-Key).-
Input locale: French.'
       , 16, 1
       , to_number('00100')
       , 102055
       , 'orderable'
       , 48
       , 39
       , 'http://www.supp-102055.com/cat/hw/p3110.html');
INSERT INTO A_product_information
VALUES ( 3108 -
       , 'KB E/EN' -
       , 'Ergonomic Keyboard with two separate key areas,-
detachable numeric pad. Key layout: English (US).'
       , 16, 2
       , to_number('00200')
       , 102055
       , 'orderable'
       , 78
       , 63
       , 'http://www.supp-102055.com/cat/hw/p3108.html');
INSERT INTO A_product_information
VALUES ( 2058 -
       , 'Mouse 0WP' -
       , 'Combination of a mouse and a wrist pad for more-
comfortable typing and mouse operation.'
       , 16, 1
       , to_number('00100')
       , 102055
       , 'orderable'
       , 23
       , 19
       , 'http://www.supp-102055.com/cat/hw/p2058.html');
INSERT INTO A_product_information
VALUES ( 2761 -
       , 'Mouse 0WP/CL' -
       , 'Set consisting of a mouse and wrist pad,-
with corporate logo'
       , 16, 1
       , to_number('00106')
       , 102099
       , 'planned'
       , 27
       , 23
       , 'http://www.supp-102099.com/cat/hw/p2761.html');
INSERT INTO A_product_information
VALUES ( 3117 -
       , 'Mouse C/E' -
       , 'Ergonomic, cordless mouse. With track-ball-
for maximum comfort and ease of use.'
       , 16, 1
       , to_number('00100')
       , 102099
       , 'orderable'
       , 41
       , 35
       , 'http://www.supp-102099.com/cat/hw/p3117.html');
INSERT INTO A_product_information
VALUES ( 2056 -
       , 'Mouse Pad /CL' -
       , 'Standard mouse pad, with corporate logo'
       , 16, 1
       , to_number('00100')
       , 102099
       , 'planned'
       , 8
       , 6
       , 'http://www.supp-102099.com/cat/hw/p2056.html');
INSERT INTO A_product_information
VALUES ( 2211 -
       , 'Wrist Pad' -
       , 'A foam strip to support your wrists when using a keyboard'
       , 16, 1
       , to_number('00100')
       , 102072
       , 'orderable'
       , 4
       , 3
       , 'http://www.supp-102072.com/cat/hw/p2211.html');
INSERT INTO A_product_information
VALUES ( 2944 -
       , 'Wrist Pad /CL' -
       , 'Wrist Pad with corporate logo'
       , 16, 1
       , to_number('00100')
       , 102063
       , 'under development'
       , 3
       , 2
       , 'http://www.supp-102063.com/cat/hw/p2944.html');
INSERT INTO A_product_information
VALUES ( 1742 -
       , 'CD-ROM 500/16x' -
       , 'CD drive, read only, speed 16x, maximum capacity 500 MB.'
       , 17, 1
       , to_number('00006')
       , 102052
       , 'orderable'
       , 101
       , 81
       , 'http://www.supp-102052.com/cat/hw/p1742.html');
INSERT INTO A_product_information
VALUES ( 2402 -
       , 'CD-ROM 600/E/24x' -
       , '600 MB external 24x speed CD-ROM drive (read only).'
       , 17, 2
       , to_number('00009')
       , 102052
       , 'orderable'
       , 127
       , 113
       , 'http://www.supp-102052.com/cat/hw/p2402.html');
INSERT INTO A_product_information
VALUES ( 2403 -
       , 'CD-ROM 600/I/24x' -
       , '600 MB internal read only CD-ROM drive,-
reading speed 24x'
       , 17, 2
       , to_number('00100')
       , 102052
       , 'orderable'
       , 117
       , 103
       , 'http://www.supp-102052.com/cat/hw/p2403.html');
INSERT INTO A_product_information
VALUES ( 1761 -
       , 'CD-ROM 600/I/32x' -
       , '600 MB Internal CD-ROM Drive, speed 32x (read only).'
       , 17, 2
       , to_number('00100')
       , 102052
       , 'under development'
       , 134
       , 119
       , 'http://www.supp-102052.com/cat/hw/p1761.html');
INSERT INTO A_product_information
VALUES ( 2381 -
       , 'CD-ROM 8x' -
       , 'CD Writer, read only, speed 8x'
       , 17, 1
       , to_number('00003')
       , 102052
       , 'obsolete'
       , 99
       , 82
       , 'http://www.supp-102052.com/cat/hw/p2381.html');
INSERT INTO A_product_information
VALUES ( 2424 -
       , 'CDW 12/24' -
       , 'CD Writer, speed 12x write, 24x read. Warning: will become obsolete very-
soon; this speed is not high enough anymore, and better alternatives are-
available for a reasonable price.'
       , 17, 2
       , to_number('00006')
       , 102075
       , 'orderable'
       , 221
       , 198
       , 'http://www.supp-102075.com/cat/hw/p2424.html');
INSERT INTO A_product_information
VALUES ( 1781 -
       , 'CDW 20/48/E' -
       , 'CD Writer, read 48x, write 20x'
       , 17, 2
       , to_number('00009')
       , 102060
       , 'orderable'
       , 233
       , 206
       , 'http://www.supp-102060.com/cat/hw/p1781.html');
INSERT INTO A_product_information
VALUES ( 2264 -
       , 'CDW 20/48/I' -
       , 'CD-ROM drive: read 20x, write 48x (internal)'
       , 17, 2
       , to_number('00009')
       , 102060
       , 'orderable'
       , 223
       , 181
       , 'http://www.supp-102060.com/cat/hw/p2264.html');
INSERT INTO A_product_information
VALUES ( 2260 -
       , 'DFD 1.44/3.5' -
       , 'Dual Floppy Drive - 1.44 MB - 3.5'
       , 17, 2
       , to_number('00006')
       , 102062
       , 'orderable'
       , 67
       , 54
       , 'http://www.supp-102062.com/cat/hw/p2260.html');
INSERT INTO A_product_information
VALUES ( 2266 -
       , 'DVD 12x' -
       , 'DVD-ROM drive: speed 12x'
       , 17, 3
       , to_number('00100')
       , 102099
       , 'orderable'
       , 333
       , 270
       , 'http://www.supp-102099.com/cat/hw/p2266.html');
INSERT INTO A_product_information
VALUES ( 3077 -
       , 'DVD 8x' -
       , 'DVD - ROM drive, 8x speed. Will probably become-
obsolete pretty soon...'
       , 17, 3
       , to_number('00100')
       , 102099
       , 'orderable'
       , 274
       , 237
       , 'http://www.supp-102099.com/cat/hw/p3077.html');
INSERT INTO A_product_information
VALUES ( 2259 -
       , 'FD 1.44/3.5' -
       , 'Floppy Drive - 1.44 MB High Density-
capacity - 3.5 inch chassis'
       , 17, 1
       , to_number('00009')
       , 102086
       , 'orderable'
       , 39
       , 32
       , 'http://www.supp-102086.com/cat/hw/p2259.html');
INSERT INTO A_product_information
VALUES ( 2261 -
       , 'FD 1.44/3.5/E' -
       , 'Floppy disk drive - 1.44 MB (high density)-
capacity - 3.5 inch (external)'
       , 17, 2
       , to_number('00009')
       , 102086
       , 'orderable'
       , 42
       , 37
       , 'http://www.supp-102086.com/cat/hw/p2261.html');
INSERT INTO A_product_information
VALUES ( 3082 -
       , 'Modem - 56/90/E' -
       , 'Modem - 56kb per second, v.90 PCI Global compliant.-
External; for power supply 110V.'
       , 17, 1
       , to_number('00100')
       , 102068
       , 'orderable'
       , 81
       , 72
       , 'http://www.supp-102068.com/cat/hw/p3082.html');
INSERT INTO A_product_information
VALUES ( 2270 -
       , 'Modem - 56/90/I' -
       , 'Modem - 56kb per second, v.90 PCI Global compliant.-
Internal, for standard chassis (3.5 inch).'
       , 17, 1
       , to_number('00100')
       , 102068
       , 'orderable'
       , 66
       , 56
       , 'http://www.supp-102068.com/cat/hw/p2270.html');
INSERT INTO A_product_information
VALUES ( 2268 -
       , 'Modem - 56/H/E' -
       , 'Standard Hayes compatible modem - 56kb per second, external.-
Power supply: 220V.'
       , 17, 1
       , to_number('00100')
       , 102068
       , 'obsolete'
       , 77
       , 67
       , 'http://www.supp-102068.com/cat/hw/p2268.html');
INSERT INTO A_product_information
VALUES ( 3083 -
       , 'Modem - 56/H/I' -
       , 'Standard Hayes modem - 56kb per second, internal, for-
 standard 3.5 inch chassis.'
       , 17, 1
       , to_number('00100')
       , 102068
       , 'orderable'
       , 67
       , 56
       , 'http://www.supp-102068.com/cat/hw/p3083.html');
INSERT INTO A_product_information
VALUES ( 2374 -
       , 'Modem - C/100' -
       , 'DOCSIS/EURODOCSIS 1.0/1.1-compliant external cable modem'
       , 17, 2
       , to_number('00106')
       , 102064
       , 'orderable'
       , 65
       , 54
       , 'http://www.supp-102064.com/cat/hw/p2374.html');
INSERT INTO A_product_information
VALUES ( 1740 -
       , 'TD 12GB/DAT' -
       , 'Tape drive - 12 gigabyte capacity, DAT format.'
       , 17, 2
       , to_number('00106')
       , 102075
       , 'orderable'
       , 134
       , 111
       , 'http://www.supp-102075.com/cat/hw/p1740.html');
INSERT INTO A_product_information
VALUES ( 2409 -
       , 'TD 7GB/8' -
       , 'Tape drive, 7GB capacity, 8mm cartridge tape.'
       , 17, 2
       , to_number('00106')
       , 102054
       , 'orderable'
       , 210
       , 177
       , 'http://www.supp-102054.com/cat/hw/p2409.html');
INSERT INTO A_product_information
VALUES ( 2262 -
       , 'ZIP 100' -
       , 'ZIP Drive, 100 MB capacity (external) plus cable for-
parallel port connection'
       , 17, 2
       , to_number('00106')
       , 102054
       , 'orderable'
       , 98
       , 81
       , 'http://www.supp-102054.com/cat/hw/p2262.html');
INSERT INTO A_product_information
VALUES ( 2522 -
       , 'Battery - EL' -
       , 'Extended life battery, for laptop computers'
       , 19, 2
       , to_number('00003')
       , 102078
       , 'orderable'
       , 44
       , 39
       , 'http://www.supp-102078.com/cat/hw/p2522.html');
INSERT INTO A_product_information
VALUES ( 2278 -
       , 'Battery - NiHM' -
       , 'Rechargeable NiHM battery for laptop computers'
       , 19, 1
       , to_number('00003')
       , 102078
       , 'orderable'
       , 55
       , 48
       , 'http://www.supp-102078.com/cat/hw/p2278.html');
INSERT INTO A_product_information
VALUES ( 2418 -
       , 'Battery Backup (DA-130)' -
       , 'Single-battery charger with LED indicators'
       , 19, 1
       , to_number('00003')
       , 102074
       , 'orderable'
       , 61
       , 52
       , 'http://www.supp-102074.com/cat/hw/p2418.html');
INSERT INTO A_product_information
VALUES ( 2419 -
       , 'Battery Backup (DA-290)' -
       , 'Two-battery charger with LED indicators'
       , 19, 1
       , to_number('00003')
       , 102074
       , 'orderable'
       , 72
       , 60
       , 'http://www.supp-102074.com/cat/hw/p2419.html');
INSERT INTO A_product_information
VALUES ( 3097 -
       , 'Cable Connector - 32R' -
       , 'Cable Connector - 32 pin ribbon'
       , 19, 1
       , to_number('00000')
       , 102055
       , 'orderable'
       , 3
       , 2
       , 'http://www.supp-102055.com/cat/hw/p3097.html');
INSERT INTO A_product_information
VALUES ( 3099 -
       , 'Cable Harness' -
       , 'Cable harness to organize and bundle computer wiring'
       , 19, 1
       , to_number('00000')
       , 102055
       , 'orderable'
       , 4
       , 3
       , 'http://www.supp-102055.com/cat/hw/p3099.html');
INSERT INTO A_product_information
VALUES ( 2380 -
       , 'Cable PR/15/P' -
       , '15 foot parallel printer cable'
       , 19, 2
       , to_number('00001')
       , 102055
       , 'orderable'
       , 6
       , 5
       , 'http://www.supp-102055.com/cat/hw/p2380.html');
INSERT INTO A_product_information
VALUES ( 2408 -
       , 'Cable PR/P/6' -
       , 'Standard Centronics 6ft printer cable, parallel port'
       , 19, 1
       , to_number('00001')
       , 102055
       , 'orderable'
       , 4
       , 3
       , 'http://www.supp-102055.com/cat/hw/p2408.html');
INSERT INTO A_product_information
VALUES ( 2457 -
       , 'Cable PR/S/6' -
       , 'Standard RS232 serial printer cable, 6 feet'
       , 19, 1
       , to_number('00001')
       , 102055
       , 'orderable'
       , 5
       , 4
       , 'http://www.supp-102055.com/cat/hw/p2457.html');
INSERT INTO A_product_information
VALUES ( 2373 -
       , 'Cable RS232 10/AF' -
       , '10 ft RS232 cable with F/F and 9F/25F adapters'
       , 19, 2
       , to_number('00100')
       , 102055
       , 'orderable'
       , 6
       , 4
       , 'http://www.supp-102055.com/cat/hw/p2373.html');
INSERT INTO A_product_information
VALUES ( 1734 -
       , 'Cable RS232 10/AM' -
       , '10 ft RS232 cable with M/M and 9M/25M adapters'
       , 19, 2
       , to_number('00100')
       , 102055
       , 'orderable'
       , 6
       , 5
       , 'http://www.supp-102055.com/cat/hw/p1734.html');
INSERT INTO A_product_information
VALUES ( 1737 -
       , 'Cable SCSI 10/FW/ADS' -
       , '10ft SCSI2 F/W Adapt to DSxx0 Cable'
       , 19, 2
       , to_number('00002')
       , 102095
       , 'orderable'
       , 8
       , 6
       , 'http://www.supp-102095.com/cat/hw/p1737.html');
INSERT INTO A_product_information
VALUES ( 1745 -
       , 'Cable SCSI 20/WD->D' -
       , '20ft SCSI2 Wide Disk Store to Disk Store Cable'
       , 19, 2
       , to_number('00002')
       , 102095
       , 'orderable'
       , 9
       , 7
       , 'http://www.supp-102095.com/cat/hw/p1745.html');
INSERT INTO A_product_information
VALUES ( 2982 -
       , 'Drive Mount - A' -
       , 'Drive Mount assembly kit'
       , 19, 2
       , to_number('00001')
       , 102057
       , 'orderable'
       , 44
       , 35
       , 'http://www.supp-102057.com/cat/hw/p2982.html');
INSERT INTO A_product_information
VALUES ( 3277 -
       , 'Drive Mount - A/T' -
       , 'Drive Mount assembly kit for tower PC'
       , 19, 2
       , to_number('00100')
       , 102057
       , 'orderable'
       , 36
       , 29
       , 'http://www.supp-102057.com/cat/hw/p3277.html');
INSERT INTO A_product_information
VALUES ( 2976 -
       , 'Drive Mount - D' -
       , 'Drive Mount for desktop PC'
       , 19, 2
       , to_number('00100')
       , 102057
       , 'orderable'
       , 52
       , 44
       , 'http://www.supp-102057.com/cat/hw/p2976.html');
INSERT INTO A_product_information
VALUES ( 3204 -
       , 'Envoy DS' -
       , 'Envoy Docking Station'
       , 19, 3
       , to_number('00200')
       , 102060
       , 'orderable'
       , 126
       , 107
       , 'http://www.supp-102060.com/cat/hw/p3204.html');
INSERT INTO A_product_information
VALUES ( 2638 -
       , 'Envoy DS/E' -
       , 'Enhanced Envoy Docking Station'
       , 19, 3
       , to_number('00200')
       , 102060
       , 'orderable'
       , 137
       , 111
       , 'http://www.supp-102060.com/cat/hw/p2638.html');
INSERT INTO A_product_information
VALUES ( 3020 -
       , 'Envoy IC' -
       , 'Envoy Internet Computer, Plug&Play'
       , 19, 4
       , to_number('00100')
       , 102060
       , 'orderable'
       , 449
       , 366
       , 'http://www.supp-102060.com/cat/hw/p3020.html');
INSERT INTO A_product_information
VALUES ( 1948 -
       , 'Envoy IC/58' -
       , 'Internet computer with built-in 58K modem'
       , 19, 4
       , to_number('00106')
       , 102060
       , 'orderable'
       , 498
       , 428
       , 'http://www.supp-102060.com/cat/hw/p1948.html');
INSERT INTO A_product_information
VALUES ( 3003 -
       , 'Laptop 128/12/56/v90/110' -
       , 'Envoy Laptop, 128MB memory, 12GB hard disk, v90 modem,-
110V power supply.'
       , 19, 4
       , to_number('00106')
       , 102060
       , 'orderable'
       , 3219
       , 2606
       , 'http://www.supp-102060.com/cat/hw/p3003.html');
INSERT INTO A_product_information
VALUES ( 2999 -
       , 'Laptop 16/8/110' -
       , 'Envoy Laptop, 16MB memory, 8GB hard disk,-
110V power supply (US only).'
       , 19, 3
       , to_number('00106')
       , 102060
       , 'obsolete'
       , 999
       , 800
       , 'http://www.supp-102060.com/cat/hw/p2999.html');
INSERT INTO A_product_information
VALUES ( 3000 -
       , 'Laptop 32/10/56' -
       , 'Envoy Laptop, 32MB memory, 10GB hard disk, 56K Modem,-
universal power supply (switchable).'
       , 19, 4
       , to_number('00106')
       , 102060
       , 'orderable'
       , 1749
       , 1542
       , 'http://www.supp-102060.com/cat/hw/p3000.html');
INSERT INTO A_product_information
VALUES ( 3001 -
       , 'Laptop 48/10/56/110' -
       , 'Envoy Laptop, 48MB memory, 10GB hard disk, 56K modem,-
110V power supply.'
       , 19, 4
       , to_number('00106')
       , 102060
       , 'obsolete'
       , 2556
       , 2073
       , 'http://www.supp-102060.com/cat/hw/p3001.html');
INSERT INTO A_product_information
VALUES ( 3004 -
       , 'Laptop 64/10/56/220' -
       , 'Envoy Laptop, 64MB memory, 10GB hard disk, 56K modem,-
220V power supply.'
       , 19, 4
       , to_number('00106')
       , 102060
       , 'orderable'
       , 2768
       , 2275
       , 'http://www.supp-102060.com/cat/hw/p3004.html');
INSERT INTO A_product_information
VALUES ( 3391 -
       , 'PS 110/220' -
       , 'Power Supply - switchable, 110V/220V'
       , 19, 2
       , to_number('00106')
       , 102062
       , 'orderable'
       , 85
       , 75
       , 'http://www.supp-102062.com/cat/hw/p3391.html');
INSERT INTO A_product_information
VALUES ( 3124 -
       , 'PS 110V /T' -
       , 'Power supply for tower PC, 110V'
       , 19, 2
       , to_number('00100')
       , 102062
       , 'orderable'
       , 84
       , 70
       , 'http://www.supp-102062.com/cat/hw/p3124.html');
INSERT INTO A_product_information
VALUES ( 1738 -
       , 'PS 110V /US' -
       , '110 V Power Supply - US compatible'
       , 19, 2
       , to_number('00100')
       , 102062
       , 'orderable'
       , 86
       , 70
       , 'http://www.supp-102062.com/cat/hw/p1738.html');
INSERT INTO A_product_information
VALUES ( 2377 -
       , 'PS 110V HS/US' -
       , '110 V hot swappable power supply - US compatible'
       , 19, 2
       , to_number('00100')
       , 102062
       , 'orderable'
       , 97
       , 82
       , 'http://www.supp-102062.com/cat/hw/p2377.html');
INSERT INTO A_product_information
VALUES ( 2299 -
       , 'PS 12V /P' -
       , 'Power Supply - 12v portable'
       , 19, 2
       , to_number('00100')
       , 102062
       , 'orderable'
       , 76
       , 64
       , 'http://www.supp-102062.com/cat/hw/p2299.html');
INSERT INTO A_product_information
VALUES ( 3123 -
       , 'PS 220V /D' -
       , 'Standard power supply, 220V, for desktop computers.'
       , 19, 2
       , to_number('00100')
       , 102062
       , 'orderable'
       , 81
       , 65
       , 'http://www.supp-102062.com/cat/hw/p3123.html');
INSERT INTO A_product_information
VALUES ( 1748 -
       , 'PS 220V /EUR' -
       , '220 Volt Power supply type - Europe'
       , 19, 2
       , to_number('00100')
       , 102053
       , 'orderable'
       , 83
       , 70
       , 'http://www.supp-102053.com/cat/hw/p1748.html');
INSERT INTO A_product_information
VALUES ( 2387 -
       , 'PS 220V /FR' -
       , '220V Power supply type - France'
       , 19, 2
       , to_number('00100')
       , 102053
       , 'orderable'
       , 83
       , 66
       , 'http://www.supp-102053.com/cat/hw/p2387.html');
INSERT INTO A_product_information
VALUES ( 2370 -
       , 'PS 220V /HS/FR' -
       , '220V hot swappable power supply, for France.'
       , 19, 2
       , to_number('00009')
       , 102053
       , 'orderable'
       , 91
       , 75
       , 'http://www.supp-102053.com/cat/hw/p2370.html');
INSERT INTO A_product_information
VALUES ( 2311 -
       , 'PS 220V /L' -
       , 'Power supply for laptop computers, 220V'
       , 19, 2
       , to_number('00009')
       , 102053
       , 'orderable'
       , 95
       , 79
       , 'http://www.supp-102053.com/cat/hw/p2311.html');
INSERT INTO A_product_information
VALUES ( 1733 -
       , 'PS 220V /UK' -
       , '220V Power supply type - United Kingdom'
       , 19, 2
       , to_number('00009')
       , 102080
       , 'orderable'
       , 89
       , 76
       , 'http://www.supp-102080.com/cat/hw/p1733.html');
INSERT INTO A_product_information
VALUES ( 2878 -
       , 'Router - ASR/2W' -
       , 'Special ALS Router - Approved Supplier required item with 2-way match'
       , 19, 3
       , to_number('00009')
       , 102063
       , 'orderable'
       , 345
       , 305
       , 'http://www.supp-102063.com/cat/hw/p2878.html');
INSERT INTO A_product_information
VALUES ( 2879 -
       , 'Router - ASR/3W' -
       , 'Special ALS Router - Approved Supplier required item with 3-way match'
       , 19, 3
       , to_number('00009')
       , 102063
       , 'orderable'
       , 456
       , 384
       , 'http://www.supp-102063.com/cat/hw/p2879.html');
INSERT INTO A_product_information
VALUES ( 2152 -
       , 'Router - DTMF4' -
       , 'DTMF 4 port router'
       , 19, 3
       , to_number('00009')
       , 102063
       , 'obsolete'
       , 231
       , 191
       , 'http://www.supp-102063.com/cat/hw/p2152.html');
INSERT INTO A_product_information
VALUES ( 3301 -
       , 'Screws <B.28.P>' -
       , 'Screws: Brass, size 28mm, Phillips head. Plastic box, contents 500.'
       , 19, 2
       , to_number('00000')
       , 102071
       , 'orderable'
       , 15
       , 12
       , 'http://www.supp-102071.com/cat/hw/p3301.html');
INSERT INTO A_product_information
VALUES ( 3143 -
       , 'Screws <B.28.S>' -
       , 'Screws: Brass, size 28mm, straight. Plastic box, contents 500.'
       , 19, 2
       , to_number('00000')
       , 102071
       , 'orderable'
       , 16
       , 13
       , 'http://www.supp-102071.com/cat/hw/p3143.html');
INSERT INTO A_product_information
VALUES ( 2323 -
       , 'Screws <B.32.P>' -
       , 'Screws: Brass, size 32mm, Phillips head. Plastic box, contents 400.'
       , 19, 3
       , to_number('00000')
       , 102071
       , 'orderable'
       , 18
       , 14
       , 'http://www.supp-102071.com/cat/hw/p2323.html');
INSERT INTO A_product_information
VALUES ( 3134 -
       , 'Screws <B.32.S>' -
       , 'Screws: Brass, size 32mm, straight. Plastic box, contents 400.'
       , 19, 3
       , to_number('00000')
       , 102071
       , 'orderable'
       , 18
       , 15
       , 'http://www.supp-102071.com/cat/hw/p3134.html');
INSERT INTO A_product_information
VALUES ( 3139 -
       , 'Screws <S.16.S>' -
       , 'Screws: Steel, size 16 mm, straight. Carton box, contents 750.'
       , 19, 2
       , to_number('00000')
       , 102071
       , 'orderable'
       , 21
       , 17
       , 'http://www.supp-102071.com/cat/hw/p3139.html');
INSERT INTO A_product_information
VALUES ( 3300 -
       , 'Screws <S.32.P>' -
       , 'Screws: Steel, size 32mm, Phillips head. Plastic box, contents 400.'
       , 19, 3
       , to_number('00000')
       , 102071
       , 'orderable'
       , 23
       , 19
       , 'http://www.supp-102071.com/cat/hw/p3300.html');
INSERT INTO A_product_information
VALUES ( 2316 -
       , 'Screws <S.32.S>' -
       , 'Screws: Steel, size 32mm, straight. Plastic box, contents 500.'
       , 19, 3
       , to_number('00000')
       , 102074
       , 'orderable'
       , 22
       , 19
       , 'http://www.supp-102074.com/cat/hw/p2316.html');
INSERT INTO A_product_information
VALUES ( 3140 -
       , 'Screws <Z.16.S>' -
       , 'Screws: Zinc, length 16mm, straight. Carton box, contents 750.'
       , 19, 2
       , to_number('00000')
       , 102074
       , 'orderable'
       , 24
       , 19
       , 'http://www.supp-102074.com/cat/hw/p3140.html');
INSERT INTO A_product_information
VALUES ( 2319 -
       , 'Screws <Z.24.S>' -
       , 'Screws: Zinc, size 24mm, straight. Carton box, contents 500.'
       , 19, 2
       , to_number('00000')
       , 102074
       , 'orderable'
       , 25
       , 21
       , 'http://www.supp-102074.com/cat/hw/p2319.html');
INSERT INTO A_product_information
VALUES ( 2322 -
       , 'Screws <Z.28.P>' -
       , 'Screws: Zinc, size 28 mm, Phillips head. Carton box, contents 850.'
       , 19, 2
       , to_number('00000')
       , 102076
       , 'orderable'
       , 23
       , 18
       , 'http://www.supp-102076.com/cat/hw/p2322.html');
INSERT INTO A_product_information
VALUES ( 3178 -
       , 'Spreadsheet - SSP/V 2.0' -
       , 'SmartSpread Spreadsheet, Professional Edition Version 2.0, for Vision-
Release 11.1 and 11.2. Shrink wrap includes CD-ROM containing advanced-
software and online documentation, plus printed manual, tutorial, and-
license registration.'
       , 21, 2
       , to_number('00001')
       , 103080
       , 'orderable'
       , 45
       , 37
       , 'http://www.supp-103080.com/cat/sw/p3178.html');
INSERT INTO A_product_information
VALUES ( 3179 -
       , 'Spreadsheet - SSS/S 2.1' -
       , 'SmartSpread Spreadsheet, Standard Edition Version 2.1, for SPNIX Release-
4.0. Shrink wrap includes CD-ROM containing software and online-
documentation, plus printed manual and license registration.'
       , 21, 2
       , to_number('00001')
       , 103080
       , 'orderable'
       , 50
       , 44
       , 'http://www.supp-103080.com/cat/sw/p3179.html');
INSERT INTO A_product_information
VALUES ( 3182 -
       , 'Word Processing - SWP/V 4.5' -
       , 'SmartWord Word Processor, Professional Edition Version 4.5, for Vision-
Release 11.x. Shrink wrap includes CD-ROM, containing advanced software,-
printed manual, and license registration.'
       , 22, 2
       , to_number('00003')
       , 103093
       , 'orderable'
       , 65
       , 54
       , 'http://www.supp-103093.com/cat/sw/p3182.html');
INSERT INTO A_product_information
VALUES ( 3183 -
       , 'Word Processing - SWS/V 4.5' -
       , 'SmartWord Word Processor, Standard Edition Version 4.5, for Vision-
Release 11.x. Shrink wrap includes CD-ROM and license registration.'
       , 22, 2
       , to_number('00001')
       , 103093
       , 'orderable'
       , 50
       , 40
       , 'http://www.supp-103093.com/cat/sw/p3183.html');
INSERT INTO A_product_information
VALUES ( 3197 -
       , 'Spreadsheet - SSS/V 2.1' -
       , 'SmartSpread Spreadsheet, Standard Edition Version 2.1, for Vision-
Release 11.1 and 11.2. Shrink wrap includes CD-ROM containing software-
and online documentation, plus printed manual, tutorial, and license-
registration.'
       , 21, 2
       , to_number('00001')
       , 103080
       , 'orderable'
       , 45
       , 36
       , 'http://www.supp-103080.com/cat/sw/p3197.html');
INSERT INTO A_product_information
VALUES ( 3255 -
       , 'Spreadsheet - SSS/CD 2.2B' -
       , 'SmartSpread Spreadsheet, Standard Edition, Beta Version 2.2, for-
SPNIX Release 4.1. CD-ROM only.'
       , 21, 1
       , to_number('00001')
       , 103080
       , 'orderable'
       , 35
       , 30
       , 'http://www.supp-103080.com/cat/sw/p3255.html');
INSERT INTO A_product_information
VALUES ( 3256 -
       , 'Spreadsheet - SSS/V 2.0' -
       , 'SmartSpread Spreadsheet, Standard Edition Version 2.0, for Vision-
Release 11.0. Shrink wrap includes CD-ROM containing software and-
online documentation, plus printed manual, tutorial, and license-
registration.'
       , 21, 2
       , to_number('00001')
       , 103080
       , 'orderable'
       , 40
       , 34
       , 'http://www.supp-103080.com/cat/sw/p3256.html');
INSERT INTO A_product_information
VALUES ( 3260 -
       , 'Word Processing - SWP/S 4.4' -
       , 'SmartSpread Spreadsheet, Standard Edition Version 2.2, for SPNIX-
Release 4.x. Shrink wrap includes CD-ROM, containing software, plus-
printed manual and license registration.'
       , 22, 2
       , to_number('00001')
       , 103093
       , 'orderable'
       , 50
       , 41
       , 'http://www.supp-103093.com/cat/sw/p3260.html');
INSERT INTO A_product_information
VALUES ( 3262 -
       , 'Spreadsheet - SSS/S 2.2' -
       , 'SmartSpread Spreadsheet, Standard Edition Version 2.2, for SPNIX-
Release 4.1. Shrink wrap includes CD-ROM containing software and-
online documentation, plus printed manual and license registration.'
       , 21, 2
       , to_number('00001')
       , 103080
       , 'under development'
       , 50
       , 41
       , 'http://www.supp-103080.com/cat/sw/p3262.html');
INSERT INTO A_product_information
VALUES ( 3361 -
       , 'Spreadsheet - SSP/S 1.5' -
       , 'SmartSpread Spreadsheet, Standard Edition Version 1.5, for SPNIX-
Release 3.3. Shrink wrap includes CD-ROM containing advanced software and-
online documentation, plus printed manual, tutorial, and license registration.'
       , 21, 2
       , to_number('00001')
       , 103080
       , 'orderable'
       , 40
       , 34
       , 'http://www.supp-103080.com/cat/sw/p3361.html');
INSERT INTO A_product_information
VALUES ( 1799 -
       , 'SPNIX3.3 - SL' -
       , 'Operating System Software: SPNIX V3.3 - Base Server License. Includes-
10 general licenses for system administration, developers, or users. No-
network user licensing. '
       , 24, 1
       , to_number('00100')
       , 103092
       , 'orderable'
       , 1000
       , 874
       , 'http://www.supp-103092.com/cat/sw/p1799.html');
INSERT INTO A_product_information
VALUES ( 1801 -
       , 'SPNIX3.3 - AL' -
       , 'Operating System Software: SPNIX V3.3 - Additional system-
administrator license, including network access.'
       , 24, 1
       , to_number('00100')
       , 103092
       , 'orderable'
       , 100
       , 88
       , 'http://www.supp-103092.com/cat/sw/p1801.html');
INSERT INTO A_product_information
VALUES ( 1803 -
       , 'SPNIX3.3 - DL' -
       , 'Operating System Software: SPNIX V3.3 - Additional developer license.'
       , 24, 1
       , to_number('00100')
       , 103092
       , 'orderable'
       , 60
       , 51
       , 'http://www.supp-103092.com/cat/sw/p1803.html');
INSERT INTO A_product_information
VALUES ( 1804 -
       , 'SPNIX3.3 - UL/N' -
       , 'Operating System Software: SPNIX V3.3 - Additional user license with-
network access.'
       , 24, 1
       , to_number('00100')
       , 103092
       , 'orderable'
       , 65
       , 56
       , 'http://www.supp-103092.com/cat/sw/p1804.html');
INSERT INTO A_product_information
VALUES ( 1805 -
       , 'SPNIX3.3 - UL/A' -
       , 'Operating System Software: SPNIX V3.3 - Additional user license class A.'
       , 24, 1
       , to_number('00100')
       , 103092
       , 'orderable'
       , 50
       , 42
       , 'http://www.supp-103092.com/cat/sw/p1805.html');
INSERT INTO A_product_information
VALUES ( 1806 -
       , 'SPNIX3.3 - UL/C' -
       , 'Operating System Software: SPNIX V3.3 - Additional user license class C.'
       , 24, 1
       , to_number('00100')
       , 103092
       , 'orderable'
       , 50
       , 42
       , 'http://www.supp-103092.com/cat/sw/p1806.html');
INSERT INTO A_product_information
VALUES ( 1808 -
       , 'SPNIX3.3 - UL/D' -
       , 'Operating System Software: SPNIX V3.3 - Additional user license class D.'
       , 24, 1
       , to_number('00100')
       , 103092
       , 'orderable'
       , 55
       , 46
       , 'http://www.supp-103092.com/cat/sw/p1808.html');
INSERT INTO A_product_information
VALUES ( 1820 -
       , 'SPNIX3.3 - NL' -
       , 'Operating System Software: SPNIX V3.3 - Additional network access license.'
       , 24, 1
       , to_number('00100')
       , 103092
       , 'orderable'
       , 55
       , 45
       , 'http://www.supp-103092.com/cat/sw/p1820.html');
INSERT INTO A_product_information
VALUES ( 1822 -
       , 'SPNIX4.0 - SL' -
       , 'Operating System Software: SPNIX V4.0 - Base Server License. Includes-
10 general licenses for system administration, developers, or users. No-
network user licensing. '
       , 24, 1
       , to_number('00100')
       , 103092
       , 'orderable'
       , 1500
       , 1303
       , 'http://www.supp-103092.com/cat/sw/p1822.html');
INSERT INTO A_product_information
VALUES ( 2422 -
       , 'SPNIX4.0 - SAL' -
       , 'Operating System Software: SPNIX V4.0 - Additional system-
administrator license, including network access.'
       , 24, 1
       , to_number('00100')
       , 103092
       , 'orderable'
       , 150
       , 130
       , 'http://www.supp-103092.com/cat/sw/p2422.html');
INSERT INTO A_product_information
VALUES ( 2452 -
       , 'SPNIX4.0 - DL' -
       , 'Operating System Software: SPNIX V4.0 - Additional developer license.'
       , 24, 1
       , to_number('00100')
       , 103092
       , 'orderable'
       , 100
       , 88
       , 'http://www.supp-103092.com/cat/sw/p2452.html');
INSERT INTO A_product_information
VALUES ( 2462 -
       , 'SPNIX4.0 - UL/N' -
       , 'Operating System Software: SPNIX V4.0 - Additional user license with-
network access.'
       , 24, 1
       , to_number('00100')
       , 103092
       , 'orderable'
       , 80
       , 71
       , 'http://www.supp-103092.com/cat/sw/p2462.html');
INSERT INTO A_product_information
VALUES ( 2464 -
       , 'SPNIX4.0 - UL/A' -
       , 'Operating System Software: SPNIX V4.0 - Additional user license class A.'
       , 24, 1
       , to_number('00100')
       , 103092
       , 'orderable'
       , 70
       , 62
       , 'http://www.supp-103092.com/cat/sw/p2464.html');
INSERT INTO A_product_information
VALUES ( 2467 -
       , 'SPNIX4.0 - UL/D' -
       , 'Operating System Software: SPNIX V4.0 - Additional user license class D.'
       , 24, 1
       , to_number('00100')
       , 103092
       , 'orderable'
       , 80
       , 64
       , 'http://www.supp-103092.com/cat/sw/p2467.html');
INSERT INTO A_product_information
VALUES ( 2468 -
       , 'SPNIX4.0 - UL/C' -
       , 'Operating System Software: SPNIX V4.0 - Additional user license class C.'
       , 24, 1
       , to_number('00100')
       , 103092
       , 'orderable'
       , 75
       , 67
       , 'http://www.supp-103092.com/cat/sw/p2468.html');
INSERT INTO A_product_information
VALUES ( 2470 -
       , 'SPNIX4.0 - NL' -
       , 'Operating System Software: SPNIX V4.0 - Additional network access license.'
       , 24, 1
       , to_number('00100')
       , 103092
       , 'orderable'
       , 80
       , 70
       , 'http://www.supp-103092.com/cat/sw/p2470.html');
INSERT INTO A_product_information
VALUES ( 2471 -
       , 'SPNIX3.3 SU' -
       , 'Operating System Software: SPNIX V3.3 - Base Server License Upgrade-
to V4.0.'
       , 24, 1
       , to_number('00100')
       , 103092
       , 'orderable'
       , 500
       , 439
       , 'http://www.supp-103092.com/cat/sw/p2471.html');
INSERT INTO A_product_information
VALUES ( 2492 -
       , 'SPNIX3.3 AU' -
       , 'Operating System Software: SPNIX V3.3 - V4.0 upgrade; class A user.'
       , 24, 1
       , to_number('00100')
       , 103092
       , 'orderable'
       , 45
       , 38
       , 'http://www.supp-103092.com/cat/sw/p2492.html');
INSERT INTO A_product_information
VALUES ( 2493 -
       , 'SPNIX3.3 C/DU' -
       , 'Operating System Software: SPNIX V3.3 - V4.0 upgrade; class C or D user.'
       , 24, 1
       , to_number('00100')
       , 103092
       , 'orderable'
       , 25
       , 22
       , 'http://www.supp-103092.com/cat/sw/p2493.html');
INSERT INTO A_product_information
VALUES ( 2494 -
       , 'SPNIX3.3 NU' -
       , 'Operating System Software: SPNIX V3.3 - V4.0 upgrade;-
network access license.'
       , 24, 1
       , to_number('00100')
       , 103092
       , 'orderable'
       , 25
       , 20
       , 'http://www.supp-103092.com/cat/sw/p2494.html');
INSERT INTO A_product_information
VALUES ( 2995 -
       , 'SPNIX3.3 SAU' -
       , 'Operating System Software: SPNIX V3.3 - V4.0 upgrade; system-
administrator license.'
       , 24, 1
       , to_number('00100')
       , 103092
       , 'orderable'
       , 70
       , 62
       , 'http://www.supp-103092.com/cat/sw/p2995.html');
INSERT INTO A_product_information
VALUES ( 3290 -
       , 'SPNIX3.3 DU' -
       , 'Operating System Software: SPNIX V3.3 - V4.0 upgrade;-
developer license.'
       , 24, 1
       , to_number('00100')
       , 103092
       , 'orderable'
       , 65
       , 55
       , 'http://www.supp-103092.com/cat/sw/p3290.html');
INSERT INTO A_product_information
VALUES ( 1778 -
       , 'C for SPNIX3.3 - 1 Seat' -
       , 'C programming software for SPNIX V3.3 - single user'
       , 25, 1
       , to_number('00006')
       , 103092
       , 'orderable'
       , 62
       , 52
       , 'http://www.supp-103092.com/cat/sw/p1778.html');
INSERT INTO A_product_information
VALUES ( 1779 -
       , 'C for SPNIX3.3 - Doc' -
       , 'C programming language documentation
, SPNIX V3.3'
       , 25, 2
       , to_number('01000')
       , 103092
       , 'orderable'
       , 128
       , 112
       , 'http://www.supp-103092.com/cat/sw/p1779.html');
INSERT INTO A_product_information
VALUES ( 1780 -
       , 'C for SPNIX3.3 - Sys' -
       , 'C programming software for SPNIX V3.3 - system compiler,-
libraries, linker'
       , 25, 1
       , to_number('00006')
       , 103092
       , 'orderable'
       , 450
       , 385
       , 'http://www.supp-103092.com/cat/sw/p1780.html');
INSERT INTO A_product_information
VALUES ( 2371 -
       , 'C for SPNIX4.0 - Doc' -
       , 'C programming language documentation, SPNIX V4.0'
       , 25, 2
       , to_number('01000')
       , 103092
       , 'orderable'
       , 146
       , 119
       , 'http://www.supp-103092.com/cat/sw/p2371.html');
INSERT INTO A_product_information
VALUES ( 2423 -
       , 'C for SPNIX4.0 - 1 Seat' -
       , 'C programming software for SPNIX V4.0 - single user'
       , 25, 1
       , to_number('00006')
       , 103092
       , 'orderable'
       , 84
       , 73
       , 'http://www.supp-103092.com/cat/sw/p2423.html');
INSERT INTO A_product_information
VALUES ( 3501 -
       , 'C for SPNIX4.0 - Sys' -
       , 'C programming software for SPNIX V4.0 - system compiler,-
libraries, linker'
       , 25, 1
       , to_number('00006')
       , 103092
       , 'orderable'
       , 555
       , 448
       , 'http://www.supp-103092.com/cat/sw/p3501.html');
INSERT INTO A_product_information
VALUES ( 3502 -
       , 'C for SPNIX3.3 -Sys/U' -
       , 'C programming software for SPNIX V3.3 - 4.0 Upgrade;-
system compiler, libraries, linker'
       , 25, 1
       , to_number('00006')
       , 103092
       , 'orderable'
       , 105
       , 88
       , 'http://www.supp-103092.com/cat/sw/p3502.html');
INSERT INTO A_product_information
VALUES ( 3503 -
       , 'C for SPNIX3.3 - Seat/U' -
       , 'C programming software for SPNIX V3.3 - 4.0 Upgrade - single user'
       , 25, 1
       , to_number('00006')
       , 103092
       , 'orderable'
       , 22
       , 18
       , 'http://www.supp-103092.com/cat/sw/p3503.html');
INSERT INTO A_product_information
VALUES ( 1774 -
       , 'Base ISO CP - BL' -
       , 'Base ISO Communication Package - Base License'
       , 29, 1
       , to_number('00000')
       , 103088
       , 'orderable'
       , 110
       , 93
       , 'http://www.supp-103088.com/cat/sw/p1774.html');
INSERT INTO A_product_information
VALUES ( 1775 -
       , 'Client ISO CP - S' -
       , 'ISO Communication Package add-on license for additional SPNIX V3.3 client.'
       , 29, 1
       , to_number('00000')
       , 103087
       , 'orderable'
       , 27
       , 22
       , 'http://www.supp-103087.com/cat/sw/p1775.html');
INSERT INTO A_product_information
VALUES ( 1794 -
       , 'OSI 8-16/IL' -
       , 'OSI Layer 8 to 16 - Incremental License'
       , 29, 1
       , to_number('00000')
       , 103096
       , 'orderable'
       , 128
       , 112
       , 'http://www.supp-103096.com/cat/sw/p1794.html');
INSERT INTO A_product_information
VALUES ( 1825 -
       , 'X25 - 1 Line License' -
       , 'X25 network access control system, single user'
       , 29, 1
       , to_number('00006')
       , 103093
       , 'orderable'
       , 25
       , 21
       , 'http://www.supp-103093.com/cat/sw/p1825.html');
INSERT INTO A_product_information
VALUES ( 2004 -
       , 'IC Browser - S' -
       , 'IC Web Browser for SPNIX. Browser with network mail capability.'
       , 29, 1
       , to_number('00001')
       , 103086
       , 'orderable'
       , 90
       , 80
       , 'http://www.supp-103086.com/cat/sw/p2004.html');
INSERT INTO A_product_information
VALUES ( 2005 -
       , 'IC Browser Doc - S' -
       , 'Documentation set for IC Web Browser for SPNIX. Includes Installation-
Manual, Mail Server Administration Guide, and User Quick Reference.'
       , 29, 2
       , to_number('00000')
       , 103086
       , 'orderable'
       , 115
       , 100
       , 'http://www.supp-103086.com/cat/sw/p2005.html');
INSERT INTO A_product_information
VALUES ( 2416 -
       , 'Client ISO CP - S' -
       , 'ISO Communication Package add-on license for additional SPNIX V4.0 client.'
       , 29, 1
       , to_number('00000')
       , 103088
       , 'orderable'
       , 41
       , 36
       , 'http://www.supp-103088.com/cat/sw/p2416.html');
INSERT INTO A_product_information
VALUES ( 2417 -
       , 'Client ISO CP - V' -
       , 'ISO Communication Package add-on license for additional Vision client.'
       , 29, 1
       , to_number('00000')
       , 103088
       , 'orderable'
       , 33
       , 27
       , 'http://www.supp-103088.com/cat/sw/p2417.html');
INSERT INTO A_product_information
VALUES ( 2449 -
       , 'OSI 1-4/IL' -
       , 'OSI Layer 1 to 4 - Incremental License'
       , 29, 1
       , to_number('00000')
       , 103088
       , 'orderable'
       , 83
       , 72
       , 'http://www.supp-103088.com/cat/sw/p2449.html');
INSERT INTO A_product_information
VALUES ( 3101 -
       , 'IC Browser - V' -
       , 'IC Web Browser for Vision with manual. Browser with network mail capability.'
       , 29, 2
       , to_number('00001')
       , 103086
       , 'orderable'
       , 75
       , 67
       , 'http://www.supp-103086.com/cat/sw/p3101.html');
INSERT INTO A_product_information
VALUES ( 3170 -
       , 'Smart Suite - V/SP' -
       , 'Office Suite (SmartWrite, SmartArt, SmartSpread, SmartBrowse) for Vision.-
Spanish language software and user manuals.'
       , 29, 2
       , to_number('00006')
       , 103089
       , 'orderable'
       , 161
       , 132
       , 'http://www.supp-103089.com/cat/sw/p3170.html');
INSERT INTO A_product_information
VALUES ( 3171 -
       , 'Smart Suite - S3.3/EN' -
       , 'Office Suite (SmartWrite, SmartArt, SmartSpread, SmartBrowse) for SPNIX-
Version 3.3. English language software and user manuals.'
       , 29, 2
       , to_number('00006')
       , 103089
       , 'orderable'
       , 148
       , 120
       , 'http://www.supp-103089.com/cat/sw/p3171.html');
INSERT INTO A_product_information
VALUES ( 3172 -
       , 'Graphics - DIK0' -
       , 'Software Kit Graphics: Draw-It Kwik-Plus. Includes extensive clip art-
files and advanced drawing tools for 3-D object manipulation, variable-
shading, and extended character fonts.'
       , 29, 1
       , to_number('00001')
       , 103094
       , 'orderable'
       , 42
       , 34
       , 'http://www.supp-103094.com/cat/sw/p3172.html');
INSERT INTO A_product_information
VALUES ( 3173 -
       , 'Graphics - SA' -
       , 'Software Kit Graphics: SmartArt. Professional graphics package for-
SPNIX with multiple line styles, textures, built-in shapes and common symbols.'
       , 29, 1
       , to_number('00001')
       , 103094
       , 'orderable'
       , 86
       , 72
       , 'http://www.supp-103094.com/cat/sw/p3173.html');
INSERT INTO A_product_information
VALUES ( 3175 -
       , 'Project Management - S4.0' -
       , 'Project Management Software, for SPNIX V4.0. Software includes command-
line and graphical interface with text, graphic, spreadsheet, and-
customizable report formats.'
       , 29, 1
       , to_number('00001')
       , 103089
       , 'orderable'
       , 37
       , 32
       , 'http://www.supp-103089.com/cat/sw/p3175.html');
INSERT INTO A_product_information
VALUES ( 3176 -
       , 'Smart Suite - V/EN' -
       , 'Office Suite (SmartWrite, SmartArt, SmartSpread, SmartBrowse) for-
Vision. English language software and user manuals.'
       , 29, 2
       , to_number('00006')
       , 103089
       , 'orderable'
       , 120
       , 103
       , 'http://www.supp-103089.com/cat/sw/p3176.html');
INSERT INTO A_product_information
VALUES ( 3177 -
       , 'Smart Suite - V/FR' -
       , 'Office Suite (SmartWrite, SmartArt, SmartSpread, SmartBrowse) for-
Vision. French language software and user manuals.'
       , 29, 2
       , to_number('00006')
       , 103089
       , 'orderable'
       , 120
       , 102
       , 'http://www.supp-103089.com/cat/sw/p3177.html');
INSERT INTO A_product_information
VALUES ( 3245 -
       , 'Smart Suite - S4.0/FR' -
       , 'Office Suite (SmartWrite, SmartArt, SmartSpread, SmartBrowse) for-
SPNIX V4.0. French language software and user manuals.'
       , 29, 2
       , to_number('00006')
       , 103089
       , 'orderable'
       , 222
       , 195
       , 'http://www.supp-103089.com/cat/sw/p3245.html');
INSERT INTO A_product_information
VALUES ( 3246 -
       , 'Smart Suite - S4.0/SP' -
       , 'Office Suite (SmartWrite, SmartArt, SmartSpread, SmartBrowse) for-
SPNIX V4.0. Spanish language software and user manuals.'
       , 29, 2
       , to_number('00006')
       , 103089
       , 'orderable'
       , 222
       , 193
       , 'http://www.supp-103089.com/cat/sw/p3246.html');
INSERT INTO A_product_information
VALUES ( 3247 -
       , 'Smart Suite - V/DE' -
       , 'Office Suite (SmartWrite, SmartArt, SmartSpread, SmartBrowse) for-
Vision. German language software and user manuals.'
       , 29, 2
       , to_number('00006')
       , 103089
       , 'orderable'
       , 120
       , 96
       , 'http://www.supp-103089.com/cat/sw/p3247.html');
INSERT INTO A_product_information
VALUES ( 3248 -
       , 'Smart Suite - S4.0/DE' -
       , 'Office Suite (SmartWrite, SmartArt, SmartSpread, SmartBrowse) for-
SPNIX V4.0. German language software and user manuals.'
       , 29, 2
       , to_number('00006')
       , 103089
       , 'orderable'
       , 222
       , 193
       , 'http://www.supp-103089.com/cat/sw/p3248.html');
INSERT INTO A_product_information
VALUES ( 3250 -
       , 'Graphics - DIK' -
       , 'Software Kit Graphics: Draw-It Kwik. Simple graphics package for-
Vision systems, with options to save in GIF, JPG, and BMP formats.'
       , 29, 1
       , to_number('00001')
       , 103083
       , 'orderable'
       , 28
       , 24
       , 'http://www.supp-103083.com/cat/sw/p3250.html');
INSERT INTO A_product_information
VALUES ( 3251 -
       , 'Project Management - V' -
       , 'Project Management Software, for Vision. Software includes command-
line and graphical interface with text, graphic, spreadsheet, and-
customizable report formats.'
       , 29, 1
       , to_number('00001')
       , 103093
       , 'orderable'
       , 31
       , 26
       , 'http://www.supp-103093.com/cat/sw/p3251.html');
INSERT INTO A_product_information
VALUES ( 3252 -
       , 'Project Management - S3.3' -
       , 'Project Management Software, for SPNIX V3.3. Software includes command-
line and graphical interface with text, graphic, spreadsheet, and-
customizable report formats.'
       , 29, 1
       , to_number('00001')
       , 103093
       , 'orderable'
       , 26
       , 23
       , 'http://www.supp-103093.com/cat/sw/p3252.html');
INSERT INTO A_product_information
VALUES ( 3253 -
       , 'Smart Suite - S4.0/EN' -
       , 'Office Suite (SmartWrite, SmartArt, SmartSpread, SmartBrowse) for-
SPNIX V4.0. English language software and user manuals.'
       , 29, 2
       , to_number('00006')
       , 103089
       , 'orderable'
       , 222
       , 188
       , 'http://www.supp-103089.com/cat/sw/p3253.html');
INSERT INTO A_product_information
VALUES ( 3257 -
       , 'Web Browser - SB/S 2.1' -
       , 'Software Kit Web Browser: SmartBrowse V2.1 for SPNIX V3.3. Includes-
context sensitive help files and online documentation.'
       , 29, 1
       , to_number('00001')
       , 103082
       , 'orderable'
       , 66
       , 58
       , 'http://www.supp-103082.com/cat/sw/p3257.html');
INSERT INTO A_product_information
VALUES ( 3258 -
       , 'Web Browser - SB/V 1.0' -
       , 'Software Kit Web Browser: SmartBrowse V2.1 for Vision. Includes-
context sensitive help files and online documentation.'
       , 29, 1
       , to_number('00001')
       , 103082
       , 'orderable'
       , 80
       , 70
       , 'http://www.supp-103082.com/cat/sw/p3258.html');
INSERT INTO A_product_information
VALUES ( 3362 -
       , 'Web Browser - SB/S 4.0' -
       , 'Software Kit Web Browser: SmartBrowse V4.0 for SPNIX V4.0. Includes-
context sensitive help files and online documentation.'
       , 29, 1
       , to_number('00001')
       , 103082
       , 'orderable'
       , 99
       , 81
       , 'http://www.supp-103082.com/cat/sw/p3362.html');
INSERT INTO A_product_information
VALUES ( 2231 -
       , 'Desk - S/V' -
       , 'Standard-sized desk; capitalizable, taxable item. Final finish is from-
veneer in stock at time of order, including oak, ash, cherry, and mahogany.'
       , 31, 5
       , to_number('01500')
       , 103082
       , 'orderable'
       , 2510
       , 2114
       , 'http://www.supp-103082.com/cat/off/p2231.html');
INSERT INTO A_product_information
VALUES ( 2335 -
       , 'Mobile phone' -
       , 'Dual band mobile phone with low battery consumption. Lightweight,-
foldable, with socket for single earphone and spare battery compartment.'
       , 31, 1
       , to_number('00106')
       , 103088
       , 'orderable'
       , 100
       , 83
       , 'http://www.supp-103088.com/cat/off/p2335.html');
INSERT INTO A_product_information
VALUES ( 2350 -
       , 'Desk - W/48' -
       , 'Desk - 48 inch white laminate without return; capitalizable, taxable item.'
       , 31, 5
       , to_number('02000')
       , 103082
       , 'orderable'
       , 2500
       , 2129
       , 'http://www.supp-103082.com/cat/off/p2350.html');
INSERT INTO A_product_information
VALUES ( 2351 -
       , 'Desk - W/48/R' -
       , 'Desk - 60 inch white laminate with 48 inch return; capitalizable,-
taxable item.'
       , 31, 5
       , to_number('0200')
       , 103082
       , 'orderable'
       , 2900
       , 2386
       , 'http://www.supp-103082.com/cat/off/p2351.html');
INSERT INTO A_product_information
VALUES ( 2779 -
       , 'Desk - OS/O/F' -
       , 'Executive-style oversized oak desk with file drawers. Final finish is-
customizable when ordered, light or dark oak stain,-
or natural hand rubbed clear.'
       , 31, 5
       , to_number('02500')
       , 103082
       , 'orderable'
       , 3980
       , 3347
       , 'http://www.supp-103082.com/cat/off/p2779.html');
INSERT INTO A_product_information
VALUES ( 3337 -
       , 'Mobile Web Phone' -
       , 'Mobile phone including monthly fee for Web access. Slimline shape-
with leather-look carrying case and belt clip.'
       , 31, 2
       , to_number('00106')
       , 103088
       , 'orderable'
       , 800
       , 666
       , 'http://www.supp-103088.com/cat/off/p3337.html');
INSERT INTO A_product_information
VALUES ( 2091 -
       , 'Paper Tablet LW 8 1/2 x 11' -
       , 'Paper tablet, lined, white, size 8 1/2 x 11 inch'
       , 32, 1
       , to_number('00000')
       , 103095
       , 'orderable'
       , 1
       , 0
       , 'http://www.supp-103095.com/cat/off/p2091.html');
INSERT INTO A_product_information
VALUES ( 2093 -
       , 'Pens - 10/FP' -
       , 'Permanent ink pen dries quickly and is smear resistant. Provides smooth,-
skip-free writing. Fine point. Single color boxes (black, blue, red) or-
assorted box (6 black, 3 blue, and 1 red).'
       , 32, 1
       , to_number('00000')
       , 103090
       , 'orderable'
       , 8
       , 7
       , 'http://www.supp-103090.com/cat/off/p2093.html');
INSERT INTO A_product_information
VALUES ( 2144 -
       , 'Card Organizer Cover' -
       , 'Replacement cover for desk top style business card holder. Smoke-
grey (original color) or clear plastic.'
       , 32, 1
       , to_number('00001')
       , 103094
       , 'orderable'
       , 18
       , 14
       , 'http://www.supp-103094.com/cat/off/p2144.html');
INSERT INTO A_product_information
VALUES ( 2336 -
       , 'Business Cards Box - 250' -
       , 'Business cards box, capacity 250. Use form BC110-2, Rev. 3/2000-
(hardcopy or online) when ordering and complete all fields marked-
with an asterisk.'
       , 32, 1
       , to_number('00000')
       , 103091
       , 'orderable'
       , 55
       , 49
       , 'http://www.supp-103091.com/cat/off/p2336.html');
INSERT INTO A_product_information
VALUES ( 2337 -
       , 'Business Cards - 1000/2L' -
       , 'Business cards box, capacity 1000, 2-sided with different language on-
each side. Use form BC111-2, Rev. 12/1999 (hardcopy or online) when-
ordering - complete all fields marked with an asterisk and check box for-
second language (English is always on side 1).'
       , 32, 1
       , to_number('00000')
       , 103091
       , 'orderable'
       , 300
       , 246
       , 'http://www.supp-103091.com/cat/off/p2337.html');
INSERT INTO A_product_information
VALUES ( 2339 -
       , 'Paper - Std Printer' -
       , '20 lb. 8.5x11 inch white laser printer paper (recycled),-
ten 500-sheet reams'
       , 32, 3
       , to_number('00000')
       , 103095
       , 'orderable'
       , 25
       , 21
       , 'http://www.supp-103095.com/cat/off/p2339.html');
INSERT INTO A_product_information
VALUES ( 2536 -
       , 'Business Cards - 250/2L' -
       , 'Business cards box, capacity 250, 2-sided with different language on-
each side. Use form BC111-2, Rev. 12/1999 (hardcopy or online) when-
ordering - complete all fields marked with an asterisk and check box for-
second language (English is always on side 1).'
       , 32, 1
       , to_number('00000')
       , 103091
       , 'orderable'
       , 80
       , 68
       , 'http://www.supp-103091.com/cat/off/p2536.html');
INSERT INTO A_product_information
VALUES ( 2537 -
       , 'Business Cards Box - 1000' -
       , 'Business cards box, capacity 1000. Use form BC110-3, Rev. 3/2000-
(hardcopy or online) when ordering and complete all fields marked with-
an asterisk.'
       , 32, 1
       , to_number('00000')
       , 103091
       , 'orderable'
       , 200
       , 176
       , 'http://www.supp-103091.com/cat/off/p2537.html');
INSERT INTO A_product_information
VALUES ( 2783 -
       , 'Clips - Paper' -
       , 'World brand paper clips set the standard for quality.10 boxes with 100-
clips each. #1 regular or jumbo, smooth or non-skid.'
       , 32, 2
       , to_number('00000')
       , 103080
       , 'orderable'
       , 10
       , 8
       , 'http://www.supp-103080.com/cat/off/p2783.html');
INSERT INTO A_product_information
VALUES ( 2808 -
       , 'Paper Tablet LY 8 1/2 x 11' -
       , 'Paper Tablet, Lined, Yellow, size 8 1/2 x 11 inch'
       , 32, 1
       , to_number('00000')
       , 103098
       , 'orderable'
       , 1
       , 0
       , 'http://www.supp-103098.com/cat/off/p2808.html');
INSERT INTO A_product_information
VALUES ( 2810 -
       , 'Inkvisible Pens' -
       , 'Rollerball pen is equipped with a smooth precision tip. See-through-
rubber grip allows for a visible ink supply and comfortable writing.-
4-pack with 1 each, black, blue, red, green.'
       , 32, 1
       , to_number('00000')
       , 103095
       , 'orderable'
       , 6
       , 4
       , 'http://www.supp-103095.com/cat/off/p2810.html');
INSERT INTO A_product_information
VALUES ( 2870 -
       , 'Pencil - Mech' -
       , 'Ergonomically designed mechanical pencil for improved writing comfort.-
Refillable erasers and leads. Available in three lead sizes: .5mm (fine);-
.7mm (medium); and .9mm (thick).'
       , 32, 1
       , to_number('00200')
       , 103097
       , 'orderable'
       , 5
       , 4
       , 'http://www.supp-103097.com/cat/off/p2870.html');
INSERT INTO A_product_information
VALUES ( 3051 -
       , 'Pens - 10/MP' -
       , 'Permanent ink pen dries quickly and is smear resistant. Provides smooth,-
skip-free writing. Medium point. Single color boxes (black, blue, red) or-
assorted box (6 black, 3 blue, and 1 red).'
       , 32, 1
       , to_number('00000')
       , 103097
       , 'orderable'
       , 12
       , 10
       , 'http://www.supp-103097.com/cat/off/p3051.html');
INSERT INTO A_product_information
VALUES ( 3150 -
       , 'Card Holder - 25' -
       , 'Card Holder; heavy plastic business card holder with embossed corporate-
logo. Holds about 25 of your business cards, depending on card thickness.'
       , 32, 1
       , to_number('00006')
       , 103089
       , 'orderable'
       , 18
       , 15
       , 'http://www.supp-103089.com/cat/off/p3150.html');
INSERT INTO A_product_information
VALUES ( 3208 -
       , 'Pencils - Wood' -
       , 'Box of 2 dozen wooden pencils. Specify lead type when ordering: 2H-
(double hard), H (hard), HB (hard black), B (soft black).'
       , 32, 1
       , to_number('00000')
       , 103097
       , 'orderable'
       , 2
       , 1
       , 'http://www.supp-103097.com/cat/off/p3208.html');
INSERT INTO A_product_information
VALUES ( 3209 -
       , 'Sharpener - Pencil' -
       , 'Electric Pencil Sharpener Rugged steel cutters for long life.-
PencilSaver helps prevent over-sharpening. Non-skid rubber feet.-
Built-in pencil holder.'
       , 32, 2
       , to_number('00200')
       , 103096
       , 'orderable'
       , 13
       , 11
       , 'http://www.supp-103096.com/cat/off/p3209.html');
INSERT INTO A_product_information
VALUES ( 3224 -
       , 'Card Organizer - 250' -
       , 'Portable holder for organizing business cards, capacity 250. Booklet-
style with slip in, transparent pockets for business cards. Optional-
alphabet tabs. Specify cover color when ordering (dark brown, beige,-
burgundy, black, and light grey).'
       , 32, 1
       , to_number('00500')
       , 103095
       , 'orderable'
       , 32
       , 28
       , 'http://www.supp-103095.com/cat/off/p3224.html');
INSERT INTO A_product_information
VALUES ( 3225 -
       , 'Card Organizer - 1000' -
       , 'Holder for organizing business cards with alphabet dividers; capacity-
1000. Desk top style with smoke grey cover and black base. Lid is-
removable for storing inside drawer.'
       , 32, 1
       , to_number('00002')
       , 103095
       , 'orderable'
       , 47
       , 39
       , 'http://www.supp-103095.com/cat/off/p3225.html');
INSERT INTO A_product_information
VALUES ( 3511 -
       , 'Paper - HQ Printer' -
       , 'Quality paper for inkjet and laser printers tested to resist printer-
jams. Acid free for archival purposes. 22lb. weight with brightness of 92.-
Size: 8 1/2 x 11. Single 500-sheet ream.'
       , 32, 2
       , to_number('00000')
       , 103080
       , 'orderable'
       , 9
       , 7
       , 'http://www.supp-103080.com/cat/off/p3511.html');
INSERT INTO A_product_information
VALUES ( 3515 -
       , 'Lead Replacement' -
       , 'Refill leads for mechanical pencils. Each pack contains 25 leads and-
a replacement eraser. Available in three lead sizes: .5mm (fine); .7mm-
(medium); and .9mm (thick).'
       , 32, 1
       , to_number('00000')
       , 103095
       , 'orderable'
       , 2
       , 1
       , 'http://www.supp-103095.com/cat/off/p3515.html');
INSERT INTO A_product_information
VALUES ( 2986 -
       , 'Manual - Vision OS/2x 0' -
       , 'Manuals for Vision Operating System V 2.x and Vision Office Suite'
       , 33, 3
       , to_number('00000')
       , 103095
       , 'orderable'
       , 125
       , 111
       , 'http://www.supp-103095.com/cat/off/p2986.html');
INSERT INTO A_product_information
VALUES ( 3163 -
       , 'Manual - Vision Net6.3/US' -
       , 'Vision Networking V6.3 Reference Manual. US version with advanced-
encryption.'
       , 33, 2
       , to_number('00000')
       , 103083
       , 'orderable'
       , 35
       , 29
       , 'http://www.supp-103083.com/cat/off/p3163.html');
INSERT INTO A_product_information
VALUES ( 3165 -
       , 'Manual - Vision Tools2.0' -
       , 'Vision Business Tools Suite V2.0 Reference Manual. Includes installation,-
configuration, and user guide.'
       , 33, 2
       , to_number('00000')
       , 103083
       , 'orderable'
       , 40
       , 34
       , 'http://www.supp-103083.com/cat/off/p3165.html');
INSERT INTO A_product_information
VALUES ( 3167 -
       , 'Manual - Vision OS/2.x' -
       , 'Vision Operating System V2.0/2.1/2/3 Reference Manual. Complete-
installation, configuration, management, and tuning information for Vision-
system administration. Note that this manual replaces the individual-
Version 2.0 and 2.1 manuals.'
       , 33, 2
       , to_number('00000')
       , 103083
       , 'orderable'
       , 55
       , 47
       , 'http://www.supp-103083.com/cat/off/p3167.html');
INSERT INTO A_product_information
VALUES ( 3216 -
       , 'Manual - Vision Net6.3' -
       , 'Vision Networking V6.3 Reference Manual. Non-US version with basic-
encryption.'
       , 33, 2
       , to_number('00000')
       , 103083
       , 'orderable'
       , 30
       , 26
       , 'http://www.supp-103083.com/cat/off/p3216.html');
INSERT INTO A_product_information
VALUES ( 3220 -
       , 'Manual - Vision OS/1.2' -
       , 'Vision Operating System V1.2 Reference Manual. Complete installation,-
configuration, management, and tuning information for Vision system-
administration.'
       , 33, 2
       , to_number('00000')
       , 103083
       , 'orderable'
       , 45
       , 36
       , 'http://www.supp-103083.com/cat/off/p3220.html');
INSERT INTO A_product_information
VALUES ( 1729 -
       , 'Chemicals - RCP' -
       , 'Cleaning Chemicals - 3500 roller clean pads'
       , 39, 2
       , to_number('00500')
       , 103094
       , 'orderable'
       , 80
       , 66
       , 'http://www.supp-103094.com/cat/off/p1729.html');
INSERT INTO A_product_information
VALUES ( 1910 -
       , 'FG Stock - H' -
       , 'Fiberglass Stock - heavy duty, 1 thick'
       , 39, 3
       , to_number('00000')
       , 103083
       , 'orderable'
       , 14
       , 11
       , 'http://www.supp-103083.com/cat/off/p1910.html');
INSERT INTO A_product_information
VALUES ( 1912 -
       , 'SS Stock - 3mm' -
       , 'Stainless steel stock - 3mm. Can be predrilled for standard power-
supplies, motherboard holders, and hard drives. Please use appropriate-
template to identify model number, placement, and size of finished sheet-
when placing order for drilled sheet.'
       , 39, 2
       , to_number('00000')
       , 103083
       , 'orderable'
       , 15
       , 12
       , 'http://www.supp-103083.com/cat/off/p1912.html');
INSERT INTO A_product_information
VALUES ( 1940 -
       , 'ESD Bracelet/Clip' -
       , 'Electro static discharge bracelet with alligator clip for easy-
connection to computer chassis or other ground.'
       , 39, 1
       , to_number('00106')
       , 103095
       , 'orderable'
       , 18
       , 14
       , 'http://www.supp-103095.com/cat/off/p1940.html');
INSERT INTO A_product_information
VALUES ( 2030 -
       , 'Latex Gloves' -
       , 'Latex Gloves for assemblers, chemical handlers, fitters. Heavy duty,-
safety orange, with textured grip on fingers and thumb. Waterproof and-
shock-proof up to 220 volts/2 amps, 110 volts/5 amps. Acid proof for up-
to 5 minutes.'
       , 39, 1
       , to_number('01000')
       , 103097
       , 'orderable'
       , 12
       , 10
       , 'http://www.supp-103097.com/cat/off/p2030.html');
INSERT INTO A_product_information
VALUES ( 2326 -
       , 'Plastic Stock - Y' -
       , 'Plastic Stock - Yellow, standard quality.'
       , 39, 1
       , to_number('00000')
       , 103093
       , 'orderable'
       , 2
       , 1
       , 'http://www.supp-103093.com/cat/off/p2326.html');
INSERT INTO A_product_information
VALUES ( 2330 -
       , 'Plastic Stock - R' -
       , 'Plastic Stock - Red, standard quality.'
       , 39, 1
       , to_number('00000')
       , 103093
       , 'orderable'
       , 2
       , 1
       , 'http://www.supp-103093.com/cat/off/p2330.html');
INSERT INTO A_product_information
VALUES ( 2334 -
       , 'Resin' -
       , 'General purpose synthetic resin.'
       , 39, 2
       , to_number('00000')
       , 103087
       , 'orderable'
       , 4
       , 3
       , 'http://www.supp-103087.com/cat/off/p2334.html');
INSERT INTO A_product_information
VALUES ( 2340 -
       , 'Chemicals - SW' -
       , 'Cleaning Chemicals - 3500 staticide wipes'
       , 39, 2
       , to_number('00500')
       , 103094
       , 'orderable'
       , 72
       , 59
       , 'http://www.supp-103094.com/cat/off/p2340.html');
INSERT INTO A_product_information
VALUES ( 2365 -
       , 'Chemicals - TCS' -
       , 'Cleaning Chemical - 2500 transport cleaning sheets'
       , 39, 3
       , to_number('00500')
       , 103094
       , 'orderable'
       , 78
       , 69
       , 'http://www.supp-103094.com/cat/off/p2365.html');
INSERT INTO A_product_information
VALUES ( 2594 -
       , 'FG Stock - L' -
       , 'Fiberglass Stock - light weight for internal heat shielding, 1/4 thick'
       , 39, 2
       , to_number('00000')
       , 103098
       , 'orderable'
       , 9
       , 7
       , 'http://www.supp-103098.com/cat/off/p2594.html');
INSERT INTO A_product_information
VALUES ( 2596 -
       , 'SS Stock - 1mm' -
       , 'Stainless steel stock - 3mm. Can be predrilled for standard model-
motherboard and battery holders. Please use appropriate template to-
identify model number, placement, and size of finished sheet when placing-
order for drilled sheet.'
       , 39, 2
       , to_number('00000')
       , 103098
       , 'orderable'
       , 12
       , 10
       , 'http://www.supp-103098.com/cat/off/p2596.html');
INSERT INTO A_product_information
VALUES ( 2631 -
       , 'ESD Bracelet/QR' -
       , 'Electro Static Discharge Bracelet: 2 piece lead with quick release-
connector. One piece stays permanently attached to computer chassis with-
screw, the other is attached to the bracelet. Additional permanent-
ends available.'
       , 39, 1
       , to_number('00106')
       , 103085
       , 'orderable'
       , 15
       , 12
       , 'http://www.supp-103085.com/cat/off/p2631.html');
INSERT INTO A_product_information
VALUES ( 2721 -
       , 'PC Bag - L/S' -
       , 'Black Leather Computer Case - single laptop capacity with pockets for-
manuals, additional hardware, and work papers. Adjustable protective straps-
and removable pocket for power supply and cables.'
       , 39, 2
       , to_number('00100')
       , 103095
       , 'orderable'
       , 87
       , 70
       , 'http://www.supp-103095.com/cat/off/p2721.html');
INSERT INTO A_product_information
VALUES ( 2722 -
       , 'PC Bag - L/D' -
       , 'Black Leather Computer Case - double laptop capacity with pockets for-
additional hardware or manuals and work papers. Adjustable protective straps-
and removable pockets for power supplies and cables. Double wide shoulder-
strap for comfort.'
       , 39, 2
       , to_number('00100')
       , 103095
       , 'orderable'
       , 112
       , 99
       , 'http://www.supp-103095.com/cat/off/p2722.html');
INSERT INTO A_product_information
VALUES ( 2725 -
       , 'Machine Oil' -
       , 'Machine Oil for Lubrication of CD-ROM drive doors and slides.-
Self-cleaning adjustable nozzle for fine to medium flow.'
       , 39, 1
       , to_number('00000')
       , 103098
       , 'orderable'
       , 4
       , 3
       , 'http://www.supp-103098.com/cat/off/p2725.html');
INSERT INTO A_product_information
VALUES ( 2782 -
       , 'PC Bag - C/S' -
       , 'Canvas Computer Case - single laptop capacity with pockets for manuals,-
additional hardware, and work papers. Adjustable protective straps and-
removable pocket for power supply and cables. Outside pocket with snap-
closure for easy access while travelling.'
       , 39, 2
       , to_number('00006')
       , 103095
       , 'orderable'
       , 62
       , 50
       , 'http://www.supp-103095.com/cat/off/p2782.html');
INSERT INTO A_product_information
VALUES ( 3187 -
       , 'Plastic Stock - B/HD' -
       , 'Plastic Stock - Blue, high density.'
       , 39, 1
       , to_number('00000')
       , 103095
       , 'orderable'
       , 3
       , 2
       , 'http://www.supp-103095.com/cat/off/p3187.html');
INSERT INTO A_product_information
VALUES ( 3189 -
       , 'Plastic Stock - G' -
       , 'Plastic Stock - Green, standard density.'
       , 39, 1
       , to_number('00000')
       , 103095
       , 'orderable'
       , 2
       , 1
       , 'http://www.supp-103095.com/cat/off/p3189.html');
INSERT INTO A_product_information
VALUES ( 3191 -
       , 'Plastic Stock - O' -
       , 'Plastic Stock - Orange, standard density.'
       , 39, 1
       , to_number('00000')
       , 103095
       , 'orderable'
       , 2
       , 1
       , 'http://www.supp-103095.com/cat/off/p3191.html');
INSERT INTO A_product_information
VALUES ( 3193 -
       , 'Plastic Stock - W/HD' -
       , 'Plastic Stock - White, high density.'
       , 39, 1
       , to_number('00000')
       , 103095
       , 'orderable'
       , 3
       , 2
       , 'http://www.supp-103095.com/cat/off/p3193.html');
commit;
set define on
    rem
    rem Header: oe_p_inv.sql 09-jan-01
    rem
    rem Copyright (c) 2001 Oracle Corporation.All rights reserved.
    rem
    rem Owner : ahunold
    rem
    rem NAME
    rem oe_p_inv.sql - populate OE Common Schema
    rem
    rem DESCRIPTON
    rem Table inventories
    rem
    rem MODIFIED (MM/DD/YY)
    rem ahunold 01/
09/
01 - checkin ADE

INSERT INTO a_inventories
VALUES (1733, 1, 106);
INSERT INTO a_inventories
VALUES (1734, 1, 106);
INSERT INTO a_inventories
VALUES (1737, 1, 106);
INSERT INTO a_inventories
VALUES (1738, 1, 107);
INSERT INTO a_inventories
VALUES (1745, 1, 108);
INSERT INTO a_inventories
VALUES (1748, 1, 108);
INSERT INTO a_inventories
VALUES (2278, 1, 125);
INSERT INTO a_inventories
VALUES (2316, 1, 131);
INSERT INTO a_inventories
VALUES (2319, 1, 117);
INSERT INTO a_inventories
VALUES (2322, 1, 118);
INSERT INTO a_inventories
VALUES (2323, 1, 118);
INSERT INTO a_inventories
VALUES (2370, 1, 125);
INSERT INTO a_inventories
VALUES (2373, 1, 126);
INSERT INTO a_inventories
VALUES (2377, 1, 126);
INSERT INTO a_inventories
VALUES (2380, 1, 127);
INSERT INTO a_inventories
VALUES (2387, 1, 128);
INSERT INTO a_inventories
VALUES (2408, 1, 131);
INSERT INTO a_inventories
VALUES (2418, 1, 133);
INSERT INTO a_inventories
VALUES (2419, 1, 133);
INSERT INTO a_inventories
VALUES (2457, 1, 89);
INSERT INTO a_inventories
VALUES (2638, 1, 132);
INSERT INTO a_inventories
VALUES (2878, 1, 170);
INSERT INTO a_inventories
VALUES (2879, 1, 170);
INSERT INTO a_inventories
VALUES (3000, 1, 175);
INSERT INTO a_inventories
VALUES (3003, 1, 175);
INSERT INTO a_inventories
VALUES (3004, 1, 176);
INSERT INTO a_inventories
VALUES (3099, 1, 205);
INSERT INTO a_inventories
VALUES (3124, 1, 209);
INSERT INTO a_inventories
VALUES (3134, 1, 196);
INSERT INTO a_inventories
VALUES (3139, 1, 197);
INSERT INTO a_inventories
VALUES (3140, 1, 197);
INSERT INTO a_inventories
VALUES (3143, 1, 197);
INSERT INTO a_inventories
VALUES (3204, 1, 221);
INSERT INTO a_inventories
VALUES (3300, 1, 222);
INSERT INTO a_inventories
VALUES (3301, 1, 222);
INSERT INTO a_inventories
VALUES (3391, 1, 251);
INSERT INTO a_inventories
VALUES (1733, 2, 96);
INSERT INTO a_inventories
VALUES (1734, 2, 96);
INSERT INTO a_inventories
VALUES (1737, 2, 96);
INSERT INTO a_inventories
VALUES (1738, 2, 96);
INSERT INTO a_inventories
VALUES (1739, 2, 97);
INSERT INTO a_inventories
VALUES (1740, 2, 97);
INSERT INTO a_inventories
VALUES (1742, 2, 97);
INSERT INTO a_inventories
VALUES (1745, 2, 98);
INSERT INTO a_inventories
VALUES (1748, 2, 98);
INSERT INTO a_inventories
VALUES (1749, 2, 98);
INSERT INTO a_inventories
VALUES (1750, 2, 98);
INSERT INTO a_inventories
VALUES (1755, 2, 99);
INSERT INTO a_inventories
VALUES (1763, 2, 100);
INSERT INTO a_inventories
VALUES (1768, 2, 101);
INSERT INTO a_inventories
VALUES (1769, 2, 101);
INSERT INTO a_inventories
VALUES (1770, 2, 104);
INSERT INTO a_inventories
VALUES (1772, 2, 105);
INSERT INTO a_inventories
VALUES (1774, 2, 114);
INSERT INTO a_inventories
VALUES (1775, 2, 114);
INSERT INTO a_inventories
VALUES (1778, 2, 115);
INSERT INTO a_inventories
VALUES (1779, 2, 115);
INSERT INTO a_inventories
VALUES (1780, 2, 115);
INSERT INTO a_inventories
VALUES (1781, 2, 106);
INSERT INTO a_inventories
VALUES (1787, 2, 107);
INSERT INTO a_inventories
VALUES (1788, 2, 107);
INSERT INTO a_inventories
VALUES (1794, 2, 117);
INSERT INTO a_inventories
VALUES (1799, 2, 118);
INSERT INTO a_inventories
VALUES (1801, 2, 118);
INSERT INTO a_inventories
VALUES (1803, 2, 119);
INSERT INTO a_inventories
VALUES (1804, 2, 119);
INSERT INTO a_inventories
VALUES (1805, 2, 119);
INSERT INTO a_inventories
VALUES (1806, 2, 119);
INSERT INTO a_inventories
VALUES (1808, 2, 119);
INSERT INTO a_inventories
VALUES (1820, 2, 122);
INSERT INTO a_inventories
VALUES (1822, 2, 122);
INSERT INTO a_inventories
VALUES (1825, 2, 122);
INSERT INTO a_inventories
VALUES (2005, 2, 117);
INSERT INTO a_inventories
VALUES (2058, 2, 110);
INSERT INTO a_inventories
VALUES (2243, 2, 149);
INSERT INTO a_inventories
VALUES (2245, 2, 149);
INSERT INTO a_inventories
VALUES (2255, 2, 154);
INSERT INTO a_inventories
VALUES (2257, 2, 154);
INSERT INTO a_inventories
VALUES (2259, 2, 154);
INSERT INTO a_inventories
VALUES (2260, 2, 155);
INSERT INTO a_inventories
VALUES (2261, 2, 155);
INSERT INTO a_inventories
VALUES (2262, 2, 155);
INSERT INTO a_inventories
VALUES (2264, 2, 111);
INSERT INTO a_inventories
VALUES (2266, 2, 111);
INSERT INTO a_inventories
VALUES (2270, 2, 112);
INSERT INTO a_inventories
VALUES (2274, 2, 113);
INSERT INTO a_inventories
VALUES (2276, 2, 113);
INSERT INTO a_inventories
VALUES (2278, 2, 113);
INSERT INTO a_inventories
VALUES (2316, 2, 119);
INSERT INTO a_inventories
VALUES (2319, 2, 167);
INSERT INTO a_inventories
VALUES (2322, 2, 167);
INSERT INTO a_inventories
VALUES (2323, 2, 167);
INSERT INTO a_inventories
VALUES (2335, 2, 91);
INSERT INTO a_inventories
VALUES (2350, 2, 94);
INSERT INTO a_inventories
VALUES (2351, 2, 94);
INSERT INTO a_inventories
VALUES (2359, 2, 173);
INSERT INTO a_inventories
VALUES (2370, 2, 178);
INSERT INTO a_inventories
VALUES (2371, 2, 81);
INSERT INTO a_inventories
VALUES (2373, 2, 178);
INSERT INTO a_inventories
VALUES (2374, 2, 178);
INSERT INTO a_inventories
VALUES (2375, 2, 178);
INSERT INTO a_inventories
VALUES (2377, 2, 179);
INSERT INTO a_inventories
VALUES (2378, 2, 179);
INSERT INTO a_inventories
VALUES (2380, 2, 179);
INSERT INTO a_inventories
VALUES (2387, 2, 180);
INSERT INTO a_inventories
VALUES (2394, 2, 181);
INSERT INTO a_inventories
VALUES (2395, 2, 182);
INSERT INTO a_inventories
VALUES (2396, 2, 182);
INSERT INTO a_inventories
VALUES (2402, 2, 183);
INSERT INTO a_inventories
VALUES (2403, 2, 183);
INSERT INTO a_inventories
VALUES (2404, 2, 183);
INSERT INTO a_inventories
VALUES (2406, 2, 183);
INSERT INTO a_inventories
VALUES (2408, 2, 184);
INSERT INTO a_inventories
VALUES (2409, 2, 184);
INSERT INTO a_inventories
VALUES (2410, 2, 184);
INSERT INTO a_inventories
VALUES (2411, 2, 184);
INSERT INTO a_inventories
VALUES (2414, 2, 185);
INSERT INTO a_inventories
VALUES (2415, 2, 185);
INSERT INTO a_inventories
VALUES (2416, 2, 88);
INSERT INTO a_inventories
VALUES (2417, 2, 88);
INSERT INTO a_inventories
VALUES (2418, 2, 185);
INSERT INTO a_inventories
VALUES (2419, 2, 185);
INSERT INTO a_inventories
VALUES (2422, 2, 89);
INSERT INTO a_inventories
VALUES (2423, 2, 89);
INSERT INTO a_inventories
VALUES (2424, 2, 186);
INSERT INTO a_inventories
VALUES (2439, 2, 191);
INSERT INTO a_inventories
VALUES (2449, 2, 93);
INSERT INTO a_inventories
VALUES (2452, 2, 94);
INSERT INTO a_inventories
VALUES (2457, 2, 194);
INSERT INTO a_inventories
VALUES (2462, 2, 95);
INSERT INTO a_inventories
VALUES (2464, 2, 96);
INSERT INTO a_inventories
VALUES (2467, 2, 96);
INSERT INTO a_inventories
VALUES (2468, 2, 96);
INSERT INTO a_inventories
VALUES (2470, 2, 97);
INSERT INTO a_inventories
VALUES (2471, 2, 97);
INSERT INTO a_inventories
VALUES (2492, 2, 101);
INSERT INTO a_inventories
VALUES (2493, 2, 101);
INSERT INTO a_inventories
VALUES (2494, 2, 101);
INSERT INTO a_inventories
VALUES (2638, 2, 120);
INSERT INTO a_inventories
VALUES (2752, 2, 138);
INSERT INTO a_inventories
VALUES (2779, 2, 128);
INSERT INTO a_inventories
VALUES (2878, 2, 158);
INSERT INTO a_inventories
VALUES (2879, 2, 158);
INSERT INTO a_inventories
VALUES (3000, 2, 177);
INSERT INTO a_inventories
VALUES (3003, 2, 178);
INSERT INTO a_inventories
VALUES (3004, 2, 178);
INSERT INTO a_inventories
VALUES (3054, 2, 171);
INSERT INTO a_inventories
VALUES (3057, 2, 172);
INSERT INTO a_inventories
VALUES (3060, 2, 172);
INSERT INTO a_inventories
VALUES (3061, 2, 173);
INSERT INTO a_inventories
VALUES (3065, 2, 173);
INSERT INTO a_inventories
VALUES (3071, 2, 174);
INSERT INTO a_inventories
VALUES (3072, 2, 174);
INSERT INTO a_inventories
VALUES (3077, 2, 175);
INSERT INTO a_inventories
VALUES (3082, 2, 176);
INSERT INTO a_inventories
VALUES (3083, 2, 176);
INSERT INTO a_inventories
VALUES (3086, 2, 176);
INSERT INTO a_inventories
VALUES (3088, 2, 177);
INSERT INTO a_inventories
VALUES (3090, 2, 177);
INSERT INTO a_inventories
VALUES (3091, 2, 177);
INSERT INTO a_inventories
VALUES (3099, 2, 193);
INSERT INTO a_inventories
VALUES (3108, 2, 194);
INSERT INTO a_inventories
VALUES (3110, 2, 195);
INSERT INTO a_inventories
VALUES (3112, 2, 195);
INSERT INTO a_inventories
VALUES (3117, 2, 196);
INSERT INTO a_inventories
VALUES (3124, 2, 197);
INSERT INTO a_inventories
VALUES (3129, 2, 198);
INSERT INTO a_inventories
VALUES (3134, 2, 184);
INSERT INTO a_inventories
VALUES (3139, 2, 185);
INSERT INTO a_inventories
VALUES (3140, 2, 185);
INSERT INTO a_inventories
VALUES (3143, 2, 185);
INSERT INTO a_inventories
VALUES (3165, 2, 189);
INSERT INTO a_inventories
VALUES (3167, 2, 189);
INSERT INTO a_inventories
VALUES (3170, 2, 212);
INSERT INTO a_inventories
VALUES (3171, 2, 213);
INSERT INTO a_inventories
VALUES (3172, 2, 213);
INSERT INTO a_inventories
VALUES (3173, 2, 213);
INSERT INTO a_inventories
VALUES (3175, 2, 213);
INSERT INTO a_inventories
VALUES (3176, 2, 213);
INSERT INTO a_inventories
VALUES (3177, 2, 214);
INSERT INTO a_inventories
VALUES (3178, 2, 214);
INSERT INTO a_inventories
VALUES (3179, 2, 214);
INSERT INTO a_inventories
VALUES (3182, 2, 214);
INSERT INTO a_inventories
VALUES (3183, 2, 214);
INSERT INTO a_inventories
VALUES (3204, 2, 209);
INSERT INTO a_inventories
VALUES (3246, 2, 225);
INSERT INTO a_inventories
VALUES (3247, 2, 225);
INSERT INTO a_inventories
VALUES (3248, 2, 225);
INSERT INTO a_inventories
VALUES (3250, 2, 226);
INSERT INTO a_inventories
VALUES (3251, 2, 226);
INSERT INTO a_inventories
VALUES (3252, 2, 226);
INSERT INTO a_inventories
VALUES (3253, 2, 226);
INSERT INTO a_inventories
VALUES (3255, 2, 226);
INSERT INTO a_inventories
VALUES (3256, 2, 227);
INSERT INTO a_inventories
VALUES (3257, 2, 227);
INSERT INTO a_inventories
VALUES (3258, 2, 227);
INSERT INTO a_inventories
VALUES (3260, 2, 227);
INSERT INTO a_inventories
VALUES (3300, 2, 210);
INSERT INTO a_inventories
VALUES (3301, 2, 210);
INSERT INTO a_inventories
VALUES (3331, 2, 215);
INSERT INTO a_inventories
VALUES (3334, 2, 216);
INSERT INTO a_inventories
VALUES (3337, 2, 264);
INSERT INTO a_inventories
VALUES (3350, 2, 232);
INSERT INTO a_inventories
VALUES (3354, 2, 219);
INSERT INTO a_inventories
VALUES (3355, 2, 219);
INSERT INTO a_inventories
VALUES (3359, 2, 220);
INSERT INTO a_inventories
VALUES (3361, 2, 244);
INSERT INTO a_inventories
VALUES (3362, 2, 244);
INSERT INTO a_inventories
VALUES (3391, 2, 239);
INSERT INTO a_inventories
VALUES (3400, 2, 226);
INSERT INTO a_inventories
VALUES (3501, 2, 353);
INSERT INTO a_inventories
VALUES (3502, 2, 267);
INSERT INTO a_inventories
VALUES (3503, 2, 267);
INSERT INTO a_inventories
VALUES (1729, 3, 100);
INSERT INTO a_inventories
VALUES (1733, 3, 88);
INSERT INTO a_inventories
VALUES (1734, 3, 88);
INSERT INTO a_inventories
VALUES (1737, 3, 89);
INSERT INTO a_inventories
VALUES (1738, 3, 89);
INSERT INTO a_inventories
VALUES (1745, 3, 90);
INSERT INTO a_inventories
VALUES (1748, 3, 90);
INSERT INTO a_inventories
VALUES (1912, 3, 112);
INSERT INTO a_inventories
VALUES (1940, 3, 66);
INSERT INTO a_inventories
VALUES (2278, 3, 101);
INSERT INTO a_inventories
VALUES (2316, 3, 107);
INSERT INTO a_inventories
VALUES (2319, 3, 118);
INSERT INTO a_inventories
VALUES (2322, 3, 118);
INSERT INTO a_inventories
VALUES (2323, 3, 118);
INSERT INTO a_inventories
VALUES (2326, 3, 94);
INSERT INTO a_inventories
VALUES (2340, 3, 69);
INSERT INTO a_inventories
VALUES (2365, 3, 73);
INSERT INTO a_inventories
VALUES (2370, 3, 126);
INSERT INTO a_inventories
VALUES (2373, 3, 126);
INSERT INTO a_inventories
VALUES (2377, 3, 127);
INSERT INTO a_inventories
VALUES (2380, 3, 127);
INSERT INTO a_inventories
VALUES (2387, 3, 131);
INSERT INTO a_inventories
VALUES (2408, 3, 135);
INSERT INTO a_inventories
VALUES (2418, 3, 136);
INSERT INTO a_inventories
VALUES (2419, 3, 136);
INSERT INTO a_inventories
VALUES (2457, 3, 142);
INSERT INTO a_inventories
VALUES (2596, 3, 87);
INSERT INTO a_inventories
VALUES (2631, 3, 93);
INSERT INTO a_inventories
VALUES (2638, 3, 108);
INSERT INTO a_inventories
VALUES (2722, 3, 107);
INSERT INTO a_inventories
VALUES (2878, 3, 146);
INSERT INTO a_inventories
VALUES (2879, 3, 146);
INSERT INTO a_inventories
VALUES (3000, 3, 245);
INSERT INTO a_inventories
VALUES (3003, 3, 246);
INSERT INTO a_inventories
VALUES (3004, 3, 246);
INSERT INTO a_inventories
VALUES (3099, 3, 181);
INSERT INTO a_inventories
VALUES (3124, 3, 185);
INSERT INTO a_inventories
VALUES (3134, 3, 272);
INSERT INTO a_inventories
VALUES (3139, 3, 273);
INSERT INTO a_inventories
VALUES (3140, 3, 273);
INSERT INTO a_inventories
VALUES (3143, 3, 273);
INSERT INTO a_inventories
VALUES (3189, 3, 181);
INSERT INTO a_inventories
VALUES (3191, 3, 181);
INSERT INTO a_inventories
VALUES (3193, 3, 181);
INSERT INTO a_inventories
VALUES (3204, 3, 197);
INSERT INTO a_inventories
VALUES (3300, 3, 304);
INSERT INTO a_inventories
VALUES (3301, 3, 304);
INSERT INTO a_inventories
VALUES (3391, 3, 227);
INSERT INTO a_inventories
VALUES (1733, 4, 63);
INSERT INTO a_inventories
VALUES (1734, 4, 63);
INSERT INTO a_inventories
VALUES (1737, 4, 63);
INSERT INTO a_inventories
VALUES (1738, 4, 64);
INSERT INTO a_inventories
VALUES (1739, 4, 64);
INSERT INTO a_inventories
VALUES (1740, 4, 67);
INSERT INTO a_inventories
VALUES (1742, 4, 67);
INSERT INTO a_inventories
VALUES (1745, 4, 68);
INSERT INTO a_inventories
VALUES (1748, 4, 68);
INSERT INTO a_inventories
VALUES (1749, 4, 68);
INSERT INTO a_inventories
VALUES (1750, 4, 68);
INSERT INTO a_inventories
VALUES (1755, 4, 69);
INSERT INTO a_inventories
VALUES (1763, 4, 70);
INSERT INTO a_inventories
VALUES (1768, 4, 71);
INSERT INTO a_inventories
VALUES (1769, 4, 71);
INSERT INTO a_inventories
VALUES (1770, 4, 71);
INSERT INTO a_inventories
VALUES (1772, 4, 72);
INSERT INTO a_inventories
VALUES (1781, 4, 73);
INSERT INTO a_inventories
VALUES (1787, 4, 74);
INSERT INTO a_inventories
VALUES (1788, 4, 74);
INSERT INTO a_inventories
VALUES (2058, 4, 88);
INSERT INTO a_inventories
VALUES (2243, 4, 74);
INSERT INTO a_inventories
VALUES (2245, 4, 74);
INSERT INTO a_inventories
VALUES (2255, 4, 76);
INSERT INTO a_inventories
VALUES (2257, 4, 76);
INSERT INTO a_inventories
VALUES (2259, 4, 76);
INSERT INTO a_inventories
VALUES (2260, 4, 76);
INSERT INTO a_inventories
VALUES (2261, 4, 76);
INSERT INTO a_inventories
VALUES (2262, 4, 77);
INSERT INTO a_inventories
VALUES (2264, 4, 87);
INSERT INTO a_inventories
VALUES (2266, 4, 87);
INSERT INTO a_inventories
VALUES (2270, 4, 88);
INSERT INTO a_inventories
VALUES (2274, 4, 89);
INSERT INTO a_inventories
VALUES (2276, 4, 89);
INSERT INTO a_inventories
VALUES (2278, 4, 89);
INSERT INTO a_inventories
VALUES (2316, 4, 95);
INSERT INTO a_inventories
VALUES (2319, 4, 86);
INSERT INTO a_inventories
VALUES (2322, 4, 86);
INSERT INTO a_inventories
VALUES (2323, 4, 86);
INSERT INTO a_inventories
VALUES (2359, 4, 95);
INSERT INTO a_inventories
VALUES (2370, 4, 97);
INSERT INTO a_inventories
VALUES (2373, 4, 97);
INSERT INTO a_inventories
VALUES (2374, 4, 97);
INSERT INTO a_inventories
VALUES (2375, 4, 97);
INSERT INTO a_inventories
VALUES (2377, 4, 98);
INSERT INTO a_inventories
VALUES (2378, 4, 98);
INSERT INTO a_inventories
VALUES (2380, 4, 98);
INSERT INTO a_inventories
VALUES (2387, 4, 99);
INSERT INTO a_inventories
VALUES (2394, 4, 100);
INSERT INTO a_inventories
VALUES (2395, 4, 100);
INSERT INTO a_inventories
VALUES (2396, 4, 101);
INSERT INTO a_inventories
VALUES (2402, 4, 102);
INSERT INTO a_inventories
VALUES (2403, 4, 102);
INSERT INTO a_inventories
VALUES (2404, 4, 102);
INSERT INTO a_inventories
VALUES (2406, 4, 102);
INSERT INTO a_inventories
VALUES (2408, 4, 103);
INSERT INTO a_inventories
VALUES (2409, 4, 103);
INSERT INTO a_inventories
VALUES (2410, 4, 103);
INSERT INTO a_inventories
VALUES (2411, 4, 103);
INSERT INTO a_inventories
VALUES (2414, 4, 103);
INSERT INTO a_inventories
VALUES (2415, 4, 104);
INSERT INTO a_inventories
VALUES (2418, 4, 104);
INSERT INTO a_inventories
VALUES (2419, 4, 104);
INSERT INTO a_inventories
VALUES (2424, 4, 105);
INSERT INTO a_inventories
VALUES (2439, 4, 107);
INSERT INTO a_inventories
VALUES (2457, 4, 110);
INSERT INTO a_inventories
VALUES (2638, 4, 96);
INSERT INTO a_inventories
VALUES (2752, 4, 114);
INSERT INTO a_inventories
VALUES (2878, 4, 134);
INSERT INTO a_inventories
VALUES (2879, 4, 134);
INSERT INTO a_inventories
VALUES (3000, 4, 210);
INSERT INTO a_inventories
VALUES (3003, 4, 211);
INSERT INTO a_inventories
VALUES (3004, 4, 211);
INSERT INTO a_inventories
VALUES (3054, 4, 219);
INSERT INTO a_inventories
VALUES (3057, 4, 219);
INSERT INTO a_inventories
VALUES (3060, 4, 223);
INSERT INTO a_inventories
VALUES (3061, 4, 223);
INSERT INTO a_inventories
VALUES (3065, 4, 223);
INSERT INTO a_inventories
VALUES (3071, 4, 224);
INSERT INTO a_inventories
VALUES (3072, 4, 225);
INSERT INTO a_inventories
VALUES (3077, 4, 225);
INSERT INTO a_inventories
VALUES (3082, 4, 226);
INSERT INTO a_inventories
VALUES (3083, 4, 226);
INSERT INTO a_inventories
VALUES (3086, 4, 227);
INSERT INTO a_inventories
VALUES (3088, 4, 227);
INSERT INTO a_inventories
VALUES (3090, 4, 227);
INSERT INTO a_inventories
VALUES (3091, 4, 228);
INSERT INTO a_inventories
VALUES (3099, 4, 169);
INSERT INTO a_inventories
VALUES (3108, 4, 170);
INSERT INTO a_inventories
VALUES (3110, 4, 171);
INSERT INTO a_inventories
VALUES (3112, 4, 171);
INSERT INTO a_inventories
VALUES (3117, 4, 172);
INSERT INTO a_inventories
VALUES (3124, 4, 173);
INSERT INTO a_inventories
VALUES (3129, 4, 174);
INSERT INTO a_inventories
VALUES (3134, 4, 234);
INSERT INTO a_inventories
VALUES (3139, 4, 235);
INSERT INTO a_inventories
VALUES (3140, 4, 235);
INSERT INTO a_inventories
VALUES (3143, 4, 236);
INSERT INTO a_inventories
VALUES (3204, 4, 185);
INSERT INTO a_inventories
VALUES (3300, 4, 266);
INSERT INTO a_inventories
VALUES (3301, 4, 266);
INSERT INTO a_inventories
VALUES (3331, 4, 271);
INSERT INTO a_inventories
VALUES (3334, 4, 272);
INSERT INTO a_inventories
VALUES (3350, 4, 208);
INSERT INTO a_inventories
VALUES (3354, 4, 275);
INSERT INTO a_inventories
VALUES (3355, 4, 275);
INSERT INTO a_inventories
VALUES (3359, 4, 276);
INSERT INTO a_inventories
VALUES (3391, 4, 215);
INSERT INTO a_inventories
VALUES (3400, 4, 282);
INSERT INTO a_inventories
VALUES (1729, 5, 71);
INSERT INTO a_inventories
VALUES (1733, 5, 46);
INSERT INTO a_inventories
VALUES (1734, 5, 46);
INSERT INTO a_inventories
VALUES (1737, 5, 47);
INSERT INTO a_inventories
VALUES (1738, 5, 47);
INSERT INTO a_inventories
VALUES (1745, 5, 48);
INSERT INTO a_inventories
VALUES (1748, 5, 48);
INSERT INTO a_inventories
VALUES (1774, 5, 73);
INSERT INTO a_inventories
VALUES (1775, 5, 74);
INSERT INTO a_inventories
VALUES (1778, 5, 74);
INSERT INTO a_inventories
VALUES (1779, 5, 74);
INSERT INTO a_inventories
VALUES (1780, 5, 74);
INSERT INTO a_inventories
VALUES (1794, 5, 77);
INSERT INTO a_inventories
VALUES (1799, 5, 77);
INSERT INTO a_inventories
VALUES (1801, 5, 78);
INSERT INTO a_inventories
VALUES (1803, 5, 78);
INSERT INTO a_inventories
VALUES (1804, 5, 78);
INSERT INTO a_inventories
VALUES (1805, 5, 78);
INSERT INTO a_inventories
VALUES (1806, 5, 78);
INSERT INTO a_inventories
VALUES (1808, 5, 79);
INSERT INTO a_inventories
VALUES (1820, 5, 81);
INSERT INTO a_inventories
VALUES (1822, 5, 81);
INSERT INTO a_inventories
VALUES (1825, 5, 82);
INSERT INTO a_inventories
VALUES (1912, 5, 90);
INSERT INTO a_inventories
VALUES (1940, 5, 44);
INSERT INTO a_inventories
VALUES (2005, 5, 69);
INSERT INTO a_inventories
VALUES (2278, 5, 77);
INSERT INTO a_inventories
VALUES (2316, 5, 83);
INSERT INTO a_inventories
VALUES (2319, 5, 62);
INSERT INTO a_inventories
VALUES (2322, 5, 63);
INSERT INTO a_inventories
VALUES (2323, 5, 63);
INSERT INTO a_inventories
VALUES (2326, 5, 70);
INSERT INTO a_inventories
VALUES (2335, 5, 85);
INSERT INTO a_inventories
VALUES (2340, 5, 86);
INSERT INTO a_inventories
VALUES (2350, 5, 88);
INSERT INTO a_inventories
VALUES (2351, 5, 88);
INSERT INTO a_inventories
VALUES (2365, 5, 90);
INSERT INTO a_inventories
VALUES (2370, 5, 73);
INSERT INTO a_inventories
VALUES (2371, 5, 84);
INSERT INTO a_inventories
VALUES (2373, 5, 74);
INSERT INTO a_inventories
VALUES (2377, 5, 74);
INSERT INTO a_inventories
VALUES (2380, 5, 75);
INSERT INTO a_inventories
VALUES (2387, 5, 76);
INSERT INTO a_inventories
VALUES (2408, 5, 79);
INSERT INTO a_inventories
VALUES (2416, 5, 42);
INSERT INTO a_inventories
VALUES (2417, 5, 42);
INSERT INTO a_inventories
VALUES (2418, 5, 81);
INSERT INTO a_inventories
VALUES (2419, 5, 81);
INSERT INTO a_inventories
VALUES (2422, 5, 42);
INSERT INTO a_inventories
VALUES (2423, 5, 43);
INSERT INTO a_inventories
VALUES (2449, 5, 47);
INSERT INTO a_inventories
VALUES (2452, 5, 47);
INSERT INTO a_inventories
VALUES (2457, 5, 87);
INSERT INTO a_inventories
VALUES (2462, 5, 49);
INSERT INTO a_inventories
VALUES (2464, 5, 49);
INSERT INTO a_inventories
VALUES (2467, 5, 50);
INSERT INTO a_inventories
VALUES (2468, 5, 50);
INSERT INTO a_inventories
VALUES (2470, 5, 50);
INSERT INTO a_inventories
VALUES (2471, 5, 50);
INSERT INTO a_inventories
VALUES (2492, 5, 54);
INSERT INTO a_inventories
VALUES (2493, 5, 54);
INSERT INTO a_inventories
VALUES (2494, 5, 54);
INSERT INTO a_inventories
VALUES (2596, 5, 63);
INSERT INTO a_inventories
VALUES (2631, 5, 69);
INSERT INTO a_inventories
VALUES (2638, 5, 84);
INSERT INTO a_inventories
VALUES (2722, 5, 83);
INSERT INTO a_inventories
VALUES (2779, 5, 92);
INSERT INTO a_inventories
VALUES (2878, 5, 122);
INSERT INTO a_inventories
VALUES (2879, 5, 122);
INSERT INTO a_inventories
VALUES (3000, 5, 184);
INSERT INTO a_inventories
VALUES (3003, 5, 184);
INSERT INTO a_inventories
VALUES (3004, 5, 185);
INSERT INTO a_inventories
VALUES (3099, 5, 157);
INSERT INTO a_inventories
VALUES (3124, 5, 161);
INSERT INTO a_inventories
VALUES (3134, 5, 208);
INSERT INTO a_inventories
VALUES (3139, 5, 209);
INSERT INTO a_inventories
VALUES (3140, 5, 209);
INSERT INTO a_inventories
VALUES (3143, 5, 209);
INSERT INTO a_inventories
VALUES (3170, 5, 163);
INSERT INTO a_inventories
VALUES (3171, 5, 163);
INSERT INTO a_inventories
VALUES (3172, 5, 163);
INSERT INTO a_inventories
VALUES (3173, 5, 163);
INSERT INTO a_inventories
VALUES (3175, 5, 164);
INSERT INTO a_inventories
VALUES (3176, 5, 164);
INSERT INTO a_inventories
VALUES (3177, 5, 164);
INSERT INTO a_inventories
VALUES (3178, 5, 164);
INSERT INTO a_inventories
VALUES (3179, 5, 164);
INSERT INTO a_inventories
VALUES (3182, 5, 165);
INSERT INTO a_inventories
VALUES (3183, 5, 165);
INSERT INTO a_inventories
VALUES (3189, 5, 157);
INSERT INTO a_inventories
VALUES (3191, 5, 157);
INSERT INTO a_inventories
VALUES (3193, 5, 157);
INSERT INTO a_inventories
VALUES (3204, 5, 173);
INSERT INTO a_inventories
VALUES (3246, 5, 175);
INSERT INTO a_inventories
VALUES (3247, 5, 175);
INSERT INTO a_inventories
VALUES (3248, 5, 175);
INSERT INTO a_inventories
VALUES (3250, 5, 176);
INSERT INTO a_inventories
VALUES (3251, 5, 176);
INSERT INTO a_inventories
VALUES (3252, 5, 176);
INSERT INTO a_inventories
VALUES (3253, 5, 176);
INSERT INTO a_inventories
VALUES (3255, 5, 176);
INSERT INTO a_inventories
VALUES (3256, 5, 177);
INSERT INTO a_inventories
VALUES (3257, 5, 177);
INSERT INTO a_inventories
VALUES (3258, 5, 177);
INSERT INTO a_inventories
VALUES (3260, 5, 177);
INSERT INTO a_inventories
VALUES (3300, 5, 237);
INSERT INTO a_inventories
VALUES (3301, 5, 237);
INSERT INTO a_inventories
VALUES (3337, 5, 199);
INSERT INTO a_inventories
VALUES (3361, 5, 193);
INSERT INTO a_inventories
VALUES (3362, 5, 194);
INSERT INTO a_inventories
VALUES (3391, 5, 203);
INSERT INTO a_inventories
VALUES (3501, 5, 220);
INSERT INTO a_inventories
VALUES (3502, 5, 216);
INSERT INTO a_inventories
VALUES (3503, 5, 216);
INSERT INTO a_inventories
VALUES (1729, 6, 58);
INSERT INTO a_inventories
VALUES (1733, 6, 29);
INSERT INTO a_inventories
VALUES (1734, 6, 30);
INSERT INTO a_inventories
VALUES (1737, 6, 30);
INSERT INTO a_inventories
VALUES (1738, 6, 30);
INSERT INTO a_inventories
VALUES (1739, 6, 30);
INSERT INTO a_inventories
VALUES (1740, 6, 30);
INSERT INTO a_inventories
VALUES (1742, 6, 31);
INSERT INTO a_inventories
VALUES (1745, 6, 31);
INSERT INTO a_inventories
VALUES (1748, 6, 32);
INSERT INTO a_inventories
VALUES (1749, 6, 32);
INSERT INTO a_inventories
VALUES (1750, 6, 32);
INSERT INTO a_inventories
VALUES (1755, 6, 33);
INSERT INTO a_inventories
VALUES (1763, 6, 34);
INSERT INTO a_inventories
VALUES (1768, 6, 35);
INSERT INTO a_inventories
VALUES (1769, 6, 35);
INSERT INTO a_inventories
VALUES (1770, 6, 35);
INSERT INTO a_inventories
VALUES (1772, 6, 36);
INSERT INTO a_inventories
VALUES (1774, 6, 62);
INSERT INTO a_inventories
VALUES (1775, 6, 62);
INSERT INTO a_inventories
VALUES (1778, 6, 62);
INSERT INTO a_inventories
VALUES (1779, 6, 62);
INSERT INTO a_inventories
VALUES (1780, 6, 63);
INSERT INTO a_inventories
VALUES (1781, 6, 37);
INSERT INTO a_inventories
VALUES (1787, 6, 38);
INSERT INTO a_inventories
VALUES (1788, 6, 38);
INSERT INTO a_inventories
VALUES (1791, 6, 39);
INSERT INTO a_inventories
VALUES (1792, 6, 39);
INSERT INTO a_inventories
VALUES (1794, 6, 65);
INSERT INTO a_inventories
VALUES (1797, 6, 39);
INSERT INTO a_inventories
VALUES (1799, 6, 66);
INSERT INTO a_inventories
VALUES (1801, 6, 66);
INSERT INTO a_inventories
VALUES (1803, 6, 66);
INSERT INTO a_inventories
VALUES (1804, 6, 66);
INSERT INTO a_inventories
VALUES (1805, 6, 66);
INSERT INTO a_inventories
VALUES (1806, 6, 67);
INSERT INTO a_inventories
VALUES (1808, 6, 67);
INSERT INTO a_inventories
VALUES (1820, 6, 69);
INSERT INTO a_inventories
VALUES (1822, 6, 69);
INSERT INTO a_inventories
VALUES (1825, 6, 70);
INSERT INTO a_inventories
VALUES (1912, 6, 29);
INSERT INTO a_inventories
VALUES (1940, 6, 33);
INSERT INTO a_inventories
VALUES (2005, 6, 84);
INSERT INTO a_inventories
VALUES (2058, 6, 66);
INSERT INTO a_inventories
VALUES (2093, 6, 58);
INSERT INTO a_inventories
VALUES (2144, 6, 66);
INSERT INTO a_inventories
VALUES (2243, 6, 30);
INSERT INTO a_inventories
VALUES (2245, 6, 30);
INSERT INTO a_inventories
VALUES (2255, 6, 34);
INSERT INTO a_inventories
VALUES (2257, 6, 35);
INSERT INTO a_inventories
VALUES (2259, 6, 35);
INSERT INTO a_inventories
VALUES (2260, 6, 35);
INSERT INTO a_inventories
VALUES (2261, 6, 35);
INSERT INTO a_inventories
VALUES (2262, 6, 35);
INSERT INTO a_inventories
VALUES (2264, 6, 63);
INSERT INTO a_inventories
VALUES (2266, 6, 63);
INSERT INTO a_inventories
VALUES (2270, 6, 64);
INSERT INTO a_inventories
VALUES (2274, 6, 65);
INSERT INTO a_inventories
VALUES (2276, 6, 65);
INSERT INTO a_inventories
VALUES (2278, 6, 65);
INSERT INTO a_inventories
VALUES (2302, 6, 69);
INSERT INTO a_inventories
VALUES (2316, 6, 71);
INSERT INTO a_inventories
VALUES (2319, 6, 44);
INSERT INTO a_inventories
VALUES (2322, 6, 45);
INSERT INTO a_inventories
VALUES (2323, 6, 45);
INSERT INTO a_inventories
VALUES (2326, 6, 58);
INSERT INTO a_inventories
VALUES (2335, 6, 71);
INSERT INTO a_inventories
VALUES (2336, 6, 60);
INSERT INTO a_inventories
VALUES (2337, 6, 60);
INSERT INTO a_inventories
VALUES (2340, 6, 72);
INSERT INTO a_inventories
VALUES (2350, 6, 73);
INSERT INTO a_inventories
VALUES (2351, 6, 74);
INSERT INTO a_inventories
VALUES (2359, 6, 51);
INSERT INTO a_inventories
VALUES (2365, 6, 76);
INSERT INTO a_inventories
VALUES (2370, 6, 53);
INSERT INTO a_inventories
VALUES (2371, 6, 71);
INSERT INTO a_inventories
VALUES (2373, 6, 53);
INSERT INTO a_inventories
VALUES (2374, 6, 53);
INSERT INTO a_inventories
VALUES (2375, 6, 53);
INSERT INTO a_inventories
VALUES (2377, 6, 54);
INSERT INTO a_inventories
VALUES (2378, 6, 54);
INSERT INTO a_inventories
VALUES (2380, 6, 54);
INSERT INTO a_inventories
VALUES (2387, 6, 55);
INSERT INTO a_inventories
VALUES (2394, 6, 56);
INSERT INTO a_inventories
VALUES (2395, 6, 56);
INSERT INTO a_inventories
VALUES (2396, 6, 57);
INSERT INTO a_inventories
VALUES (2402, 6, 58);
INSERT INTO a_inventories
VALUES (2403, 6, 58);
INSERT INTO a_inventories
VALUES (2404, 6, 58);
INSERT INTO a_inventories
VALUES (2406, 6, 58);
INSERT INTO a_inventories
VALUES (2408, 6, 59);
INSERT INTO a_inventories
VALUES (2409, 6, 59);
INSERT INTO a_inventories
VALUES (2410, 6, 59);
INSERT INTO a_inventories
VALUES (2411, 6, 59);
INSERT INTO a_inventories
VALUES (2414, 6, 59);
INSERT INTO a_inventories
VALUES (2415, 6, 60);
INSERT INTO a_inventories
VALUES (2416, 6, 78);
INSERT INTO a_inventories
VALUES (2417, 6, 29);
INSERT INTO a_inventories
VALUES (2418, 6, 60);
INSERT INTO a_inventories
VALUES (2419, 6, 60);
INSERT INTO a_inventories
VALUES (2422, 6, 29);
INSERT INTO a_inventories
VALUES (2423, 6, 29);
INSERT INTO a_inventories
VALUES (2424, 6, 61);
INSERT INTO a_inventories
VALUES (2430, 6, 65);
INSERT INTO a_inventories
VALUES (2439, 6, 66);
INSERT INTO a_inventories
VALUES (2449, 6, 34);
INSERT INTO a_inventories
VALUES (2452, 6, 34);
INSERT INTO a_inventories
VALUES (2453, 6, 68);
INSERT INTO a_inventories
VALUES (2457, 6, 69);
INSERT INTO a_inventories
VALUES (2462, 6, 36);
INSERT INTO a_inventories
VALUES (2464, 6, 36);
INSERT INTO a_inventories
VALUES (2467, 6, 37);
INSERT INTO a_inventories
VALUES (2468, 6, 37);
INSERT INTO a_inventories
VALUES (2470, 6, 37);
INSERT INTO a_inventories
VALUES (2471, 6, 37);
INSERT INTO a_inventories
VALUES (2492, 6, 41);
INSERT INTO a_inventories
VALUES (2493, 6, 41);
INSERT INTO a_inventories
VALUES (2494, 6, 41);
INSERT INTO a_inventories
VALUES (2537, 6, 42);
INSERT INTO a_inventories
VALUES (2596, 6, 51);
INSERT INTO a_inventories
VALUES (2631, 6, 57);
INSERT INTO a_inventories
VALUES (2638, 6, 72);
INSERT INTO a_inventories
VALUES (2722, 6, 71);
INSERT INTO a_inventories
VALUES (2752, 6, 90);
INSERT INTO a_inventories
VALUES (2779, 6, 80);
INSERT INTO a_inventories
VALUES (2783, 6, 81);
INSERT INTO a_inventories
VALUES (2810, 6, 85);
INSERT INTO a_inventories
VALUES (2870, 6, 94);
INSERT INTO a_inventories
VALUES (2878, 6, 110);
INSERT INTO a_inventories
VALUES (2879, 6, 110);
INSERT INTO a_inventories
VALUES (3000, 6, 163);
INSERT INTO a_inventories
VALUES (3003, 6, 164);
INSERT INTO a_inventories
VALUES (3004, 6, 164);
INSERT INTO a_inventories
VALUES (3054, 6, 172);
INSERT INTO a_inventories
VALUES (3057, 6, 172);
INSERT INTO a_inventories
VALUES (3060, 6, 173);
INSERT INTO a_inventories
VALUES (3061, 6, 173);
INSERT INTO a_inventories
VALUES (3065, 6, 174);
INSERT INTO a_inventories
VALUES (3071, 6, 175);
INSERT INTO a_inventories
VALUES (3072, 6, 175);
INSERT INTO a_inventories
VALUES (3077, 6, 176);
INSERT INTO a_inventories
VALUES (3082, 6, 176);
INSERT INTO a_inventories
VALUES (3083, 6, 177);
INSERT INTO a_inventories
VALUES (3086, 6, 177);
INSERT INTO a_inventories
VALUES (3088, 6, 177);
INSERT INTO a_inventories
VALUES (3090, 6, 178);
INSERT INTO a_inventories
VALUES (3091, 6, 178);
INSERT INTO a_inventories
VALUES (3099, 6, 145);
INSERT INTO a_inventories
VALUES (3108, 6, 146);
INSERT INTO a_inventories
VALUES (3110, 6, 147);
INSERT INTO a_inventories
VALUES (3112, 6, 147);
INSERT INTO a_inventories
VALUES (3117, 6, 148);
INSERT INTO a_inventories
VALUES (3124, 6, 149);
INSERT INTO a_inventories
VALUES (3127, 6, 149);
INSERT INTO a_inventories
VALUES (3129, 6, 150);
INSERT INTO a_inventories
VALUES (3134, 6, 185);
INSERT INTO a_inventories
VALUES (3139, 6, 185);
INSERT INTO a_inventories
VALUES (3140, 6, 186);
INSERT INTO a_inventories
VALUES (3143, 6, 186);
INSERT INTO a_inventories
VALUES (3165, 6, 141);
INSERT INTO a_inventories
VALUES (3167, 6, 141);
INSERT INTO a_inventories
VALUES (3170, 6, 149);
INSERT INTO a_inventories
VALUES (3171, 6, 149);
INSERT INTO a_inventories
VALUES (3172, 6, 150);
INSERT INTO a_inventories
VALUES (3173, 6, 150);
INSERT INTO a_inventories
VALUES (3175, 6, 150);
INSERT INTO a_inventories
VALUES (3176, 6, 150);
INSERT INTO a_inventories
VALUES (3177, 6, 150);
INSERT INTO a_inventories
VALUES (3178, 6, 151);
INSERT INTO a_inventories
VALUES (3179, 6, 151);
INSERT INTO a_inventories
VALUES (3182, 6, 151);
INSERT INTO a_inventories
VALUES (3183, 6, 151);
INSERT INTO a_inventories
VALUES (3189, 6, 145);
INSERT INTO a_inventories
VALUES (3191, 6, 145);
INSERT INTO a_inventories
VALUES (3193, 6, 145);
INSERT INTO a_inventories
VALUES (3204, 6, 161);
INSERT INTO a_inventories
VALUES (3209, 6, 148);
INSERT INTO a_inventories
VALUES (3225, 6, 150);
INSERT INTO a_inventories
VALUES (3246, 6, 161);
INSERT INTO a_inventories
VALUES (3247, 6, 162);
INSERT INTO a_inventories
VALUES (3248, 6, 162);
INSERT INTO a_inventories
VALUES (3250, 6, 162);
INSERT INTO a_inventories
VALUES (3251, 6, 162);
INSERT INTO a_inventories
VALUES (3252, 6, 162);
INSERT INTO a_inventories
VALUES (3253, 6, 163);
INSERT INTO a_inventories
VALUES (3255, 6, 163);
INSERT INTO a_inventories
VALUES (3256, 6, 163);
INSERT INTO a_inventories
VALUES (3257, 6, 163);
INSERT INTO a_inventories
VALUES (3258, 6, 163);
INSERT INTO a_inventories
VALUES (3260, 6, 164);
INSERT INTO a_inventories
VALUES (3300, 6, 214);
INSERT INTO a_inventories
VALUES (3301, 6, 214);
INSERT INTO a_inventories
VALUES (3331, 6, 221);
INSERT INTO a_inventories
VALUES (3334, 6, 222);
INSERT INTO a_inventories
VALUES (3337, 6, 184);
INSERT INTO a_inventories
VALUES (3350, 6, 184);
INSERT INTO a_inventories
VALUES (3354, 6, 225);
INSERT INTO a_inventories
VALUES (3355, 6, 225);
INSERT INTO a_inventories
VALUES (3359, 6, 226);
INSERT INTO a_inventories
VALUES (3361, 6, 180);
INSERT INTO a_inventories
VALUES (3362, 6, 180);
INSERT INTO a_inventories
VALUES (3391, 6, 191);
INSERT INTO a_inventories
VALUES (3400, 6, 232);
INSERT INTO a_inventories
VALUES (3501, 6, 320);
INSERT INTO a_inventories
VALUES (3502, 6, 202);
INSERT INTO a_inventories
VALUES (3503, 6, 203);
INSERT INTO a_inventories
VALUES (3511, 6, 212);
INSERT INTO a_inventories
VALUES (3515, 6, 213);
INSERT INTO a_inventories
VALUES (1729, 7, 46);
INSERT INTO a_inventories
VALUES (1733, 7, 63);
INSERT INTO a_inventories
VALUES (1734, 7, 63);
INSERT INTO a_inventories
VALUES (1737, 7, 63);
INSERT INTO a_inventories
VALUES (1738, 7, 63);
INSERT INTO a_inventories
VALUES (1745, 7, 65);
INSERT INTO a_inventories
VALUES (1748, 7, 65);
INSERT INTO a_inventories
VALUES (1774, 7, 50);
INSERT INTO a_inventories
VALUES (1775, 7, 50);
INSERT INTO a_inventories
VALUES (1778, 7, 50);
INSERT INTO a_inventories
VALUES (1779, 7, 51);
INSERT INTO a_inventories
VALUES (1780, 7, 51);
INSERT INTO a_inventories
VALUES (1794, 7, 53);
INSERT INTO a_inventories
VALUES (1799, 7, 54);
INSERT INTO a_inventories
VALUES (1801, 7, 54);
INSERT INTO a_inventories
VALUES (1803, 7, 55);
INSERT INTO a_inventories
VALUES (1804, 7, 55);
INSERT INTO a_inventories
VALUES (1805, 7, 55);
INSERT INTO a_inventories
VALUES (1806, 7, 55);
INSERT INTO a_inventories
VALUES (1808, 7, 55);
INSERT INTO a_inventories
VALUES (1820, 7, 57);
INSERT INTO a_inventories
VALUES (1822, 7, 58);
INSERT INTO a_inventories
VALUES (1825, 7, 58);
INSERT INTO a_inventories
VALUES (1912, 7, 18);
INSERT INTO a_inventories
VALUES (1940, 7, 22);
INSERT INTO a_inventories
VALUES (2005, 7, 58);
INSERT INTO a_inventories
VALUES (2278, 7, 53);
INSERT INTO a_inventories
VALUES (2316, 7, 59);
INSERT INTO a_inventories
VALUES (2319, 7, 27);
INSERT INTO a_inventories
VALUES (2322, 7, 27);
INSERT INTO a_inventories
VALUES (2323, 7, 27);
INSERT INTO a_inventories
VALUES (2326, 7, 46);
INSERT INTO a_inventories
VALUES (2335, 7, 57);
INSERT INTO a_inventories
VALUES (2340, 7, 58);
INSERT INTO a_inventories
VALUES (2350, 7, 60);
INSERT INTO a_inventories
VALUES (2351, 7, 60);
INSERT INTO a_inventories
VALUES (2365, 7, 62);
INSERT INTO a_inventories
VALUES (2370, 7, 35);
INSERT INTO a_inventories
VALUES (2371, 7, 58);
INSERT INTO a_inventories
VALUES (2373, 7, 35);
INSERT INTO a_inventories
VALUES (2377, 7, 36);
INSERT INTO a_inventories
VALUES (2380, 7, 36);
INSERT INTO a_inventories
VALUES (2387, 7, 37);
INSERT INTO a_inventories
VALUES (2408, 7, 41);
INSERT INTO a_inventories
VALUES (2416, 7, 66);
INSERT INTO a_inventories
VALUES (2417, 7, 66);
INSERT INTO a_inventories
VALUES (2418, 7, 45);
INSERT INTO a_inventories
VALUES (2419, 7, 45);
INSERT INTO a_inventories
VALUES (2422, 7, 17);
INSERT INTO a_inventories
VALUES (2423, 7, 17);
INSERT INTO a_inventories
VALUES (2449, 7, 21);
INSERT INTO a_inventories
VALUES (2452, 7, 21);
INSERT INTO a_inventories
VALUES (2457, 7, 51);
INSERT INTO a_inventories
VALUES (2462, 7, 23);
INSERT INTO a_inventories
VALUES (2464, 7, 23);
INSERT INTO a_inventories
VALUES (2467, 7, 24);
INSERT INTO a_inventories
VALUES (2468, 7, 24);
INSERT INTO a_inventories
VALUES (2470, 7, 24);
INSERT INTO a_inventories
VALUES (2471, 7, 24);
INSERT INTO a_inventories
VALUES (2492, 7, 28);
INSERT INTO a_inventories
VALUES (2493, 7, 28);
INSERT INTO a_inventories
VALUES (2494, 7, 28);
INSERT INTO a_inventories
VALUES (2596, 7, 39);
INSERT INTO a_inventories
VALUES (2631, 7, 45);
INSERT INTO a_inventories
VALUES (2638, 7, 60);
INSERT INTO a_inventories
VALUES (2722, 7, 59);
INSERT INTO a_inventories
VALUES (2779, 7, 68);
INSERT INTO a_inventories
VALUES (2878, 7, 98);
INSERT INTO a_inventories
VALUES (2879, 7, 98);
INSERT INTO a_inventories
VALUES (3000, 7, 143);
INSERT INTO a_inventories
VALUES (3003, 7, 143);
INSERT INTO a_inventories
VALUES (3004, 7, 144);
INSERT INTO a_inventories
VALUES (3099, 7, 133);
INSERT INTO a_inventories
VALUES (3124, 7, 137);
INSERT INTO a_inventories
VALUES (3134, 7, 167);
INSERT INTO a_inventories
VALUES (3139, 7, 168);
INSERT INTO a_inventories
VALUES (3140, 7, 168);
INSERT INTO a_inventories
VALUES (3143, 7, 168);
INSERT INTO a_inventories
VALUES (3170, 7, 136);
INSERT INTO a_inventories
VALUES (3171, 7, 136);
INSERT INTO a_inventories
VALUES (3172, 7, 136);
INSERT INTO a_inventories
VALUES (3173, 7, 137);
INSERT INTO a_inventories
VALUES (3175, 7, 137);
INSERT INTO a_inventories
VALUES (3176, 7, 137);
INSERT INTO a_inventories
VALUES (3177, 7, 137);
INSERT INTO a_inventories
VALUES (3189, 7, 133);
INSERT INTO a_inventories
VALUES (3191, 7, 133);
INSERT INTO a_inventories
VALUES (3193, 7, 133);
INSERT INTO a_inventories
VALUES (3204, 7, 149);
INSERT INTO a_inventories
VALUES (3246, 7, 148);
INSERT INTO a_inventories
VALUES (3247, 7, 148);
INSERT INTO a_inventories
VALUES (3248, 7, 149);
INSERT INTO a_inventories
VALUES (3250, 7, 149);
INSERT INTO a_inventories
VALUES (3251, 7, 149);
INSERT INTO a_inventories
VALUES (3252, 7, 149);
INSERT INTO a_inventories
VALUES (3253, 7, 149);
INSERT INTO a_inventories
VALUES (3257, 7, 150);
INSERT INTO a_inventories
VALUES (3258, 7, 150);
INSERT INTO a_inventories
VALUES (3300, 7, 196);
INSERT INTO a_inventories
VALUES (3301, 7, 196);
INSERT INTO a_inventories
VALUES (3337, 7, 170);
INSERT INTO a_inventories
VALUES (3362, 7, 167);
INSERT INTO a_inventories
VALUES (3391, 7, 179);
INSERT INTO a_inventories
VALUES (3501, 7, 294);
INSERT INTO a_inventories
VALUES (3502, 7, 189);
INSERT INTO a_inventories
VALUES (3503, 7, 189);
INSERT INTO a_inventories
VALUES (1729, 8, 34);
INSERT INTO a_inventories
VALUES (1733, 8, 49);
INSERT INTO a_inventories
VALUES (1734, 8, 49);
INSERT INTO a_inventories
VALUES (1737, 8, 49);
INSERT INTO a_inventories
VALUES (1738, 8, 50);
INSERT INTO a_inventories
VALUES (1739, 8, 50);
INSERT INTO a_inventories
VALUES (1740, 8, 50);
INSERT INTO a_inventories
VALUES (1742, 8, 50);
INSERT INTO a_inventories
VALUES (1745, 8, 51);
INSERT INTO a_inventories
VALUES (1748, 8, 51);
INSERT INTO a_inventories
VALUES (1749, 8, 51);
INSERT INTO a_inventories
VALUES (1750, 8, 51);
INSERT INTO a_inventories
VALUES (1755, 8, 52);
INSERT INTO a_inventories
VALUES (1763, 8, 54);
INSERT INTO a_inventories
VALUES (1768, 8, 54);
INSERT INTO a_inventories
VALUES (1769, 8, 54);
INSERT INTO a_inventories
VALUES (1770, 8, 5);
INSERT INTO a_inventories
VALUES (1772, 8, 5);
INSERT INTO a_inventories
VALUES (1774, 8, 38);
INSERT INTO a_inventories
VALUES (1775, 8, 39);
INSERT INTO a_inventories
VALUES (1778, 8, 39);
INSERT INTO a_inventories
VALUES (1779, 8, 39);
INSERT INTO a_inventories
VALUES (1780, 8, 39);
INSERT INTO a_inventories
VALUES (1781, 8, 6);
INSERT INTO a_inventories
VALUES (1787, 8, 7);
INSERT INTO a_inventories
VALUES (1788, 8, 7);
INSERT INTO a_inventories
VALUES (1791, 8, 8);
INSERT INTO a_inventories
VALUES (1792, 8, 8);
INSERT INTO a_inventories
VALUES (1794, 8, 42);
INSERT INTO a_inventories
VALUES (1797, 8, 9);
INSERT INTO a_inventories
VALUES (1799, 8, 42);
INSERT INTO a_inventories
VALUES (1801, 8, 43);
INSERT INTO a_inventories
VALUES (1803, 8, 43);
INSERT INTO a_inventories
VALUES (1804, 8, 43);
INSERT INTO a_inventories
VALUES (1805, 8, 43);
INSERT INTO a_inventories
VALUES (1806, 8, 44);
INSERT INTO a_inventories
VALUES (1808, 8, 44);
INSERT INTO a_inventories
VALUES (1820, 8, 46);
INSERT INTO a_inventories
VALUES (1822, 8, 46);
INSERT INTO a_inventories
VALUES (1825, 8, 47);
INSERT INTO a_inventories
VALUES (1912, 8, 7);
INSERT INTO a_inventories
VALUES (1940, 8, 11);
INSERT INTO a_inventories
VALUES (2005, 8, 32);
INSERT INTO a_inventories
VALUES (2058, 8, 44);
INSERT INTO a_inventories
VALUES (2243, 8, 47);
INSERT INTO a_inventories
VALUES (2245, 8, 47);
INSERT INTO a_inventories
VALUES (2255, 8, 49);
INSERT INTO a_inventories
VALUES (2257, 8, 49);
INSERT INTO a_inventories
VALUES (2259, 8, 50);
INSERT INTO a_inventories
VALUES (2260, 8, 50);
INSERT INTO a_inventories
VALUES (2261, 8, 50);
INSERT INTO a_inventories
VALUES (2262, 8, 50);
INSERT INTO a_inventories
VALUES (2264, 8, 39);
INSERT INTO a_inventories
VALUES (2266, 8, 39);
INSERT INTO a_inventories
VALUES (2270, 8, 40);
INSERT INTO a_inventories
VALUES (2274, 8, 41);
INSERT INTO a_inventories
VALUES (2276, 8, 41);
INSERT INTO a_inventories
VALUES (2278, 8, 41);
INSERT INTO a_inventories
VALUES (2302, 8, 45);
INSERT INTO a_inventories
VALUES (2316, 8, 47);
INSERT INTO a_inventories
VALUES (2319, 8, 12);
INSERT INTO a_inventories
VALUES (2322, 8, 12);
INSERT INTO a_inventories
VALUES (2323, 8, 13);
INSERT INTO a_inventories
VALUES (2326, 8, 34);
INSERT INTO a_inventories
VALUES (2335, 8, 44);
INSERT INTO a_inventories
VALUES (2340, 8, 45);
INSERT INTO a_inventories
VALUES (2350, 8, 47);
INSERT INTO a_inventories
VALUES (2351, 8, 47);
INSERT INTO a_inventories
VALUES (2359, 8, 18);
INSERT INTO a_inventories
VALUES (2365, 8, 49);
INSERT INTO a_inventories
VALUES (2370, 8, 20);
INSERT INTO a_inventories
VALUES (2371, 8, 46);
INSERT INTO a_inventories
VALUES (2373, 8, 20);
INSERT INTO a_inventories
VALUES (2374, 8, 21);
INSERT INTO a_inventories
VALUES (2375, 8, 21);
INSERT INTO a_inventories
VALUES (2377, 8, 21);
INSERT INTO a_inventories
VALUES (2378, 8, 21);
INSERT INTO a_inventories
VALUES (2380, 8, 22);
INSERT INTO a_inventories
VALUES (2387, 8, 23);
INSERT INTO a_inventories
VALUES (2394, 8, 24);
INSERT INTO a_inventories
VALUES (2395, 8, 24);
INSERT INTO a_inventories
VALUES (2396, 8, 24);
INSERT INTO a_inventories
VALUES (2402, 8, 25);
INSERT INTO a_inventories
VALUES (2403, 8, 25);
INSERT INTO a_inventories
VALUES (2404, 8, 25);
INSERT INTO a_inventories
VALUES (2406, 8, 26);
INSERT INTO a_inventories
VALUES (2408, 8, 26);
INSERT INTO a_inventories
VALUES (2409, 8, 26);
INSERT INTO a_inventories
VALUES (2410, 8, 26);
INSERT INTO a_inventories
VALUES (2411, 8, 26);
INSERT INTO a_inventories
VALUES (2414, 8, 27);
INSERT INTO a_inventories
VALUES (2415, 8, 27);
INSERT INTO a_inventories
VALUES (2416, 8, 53);
INSERT INTO a_inventories
VALUES (2417, 8, 53);
INSERT INTO a_inventories
VALUES (2418, 8, 28);
INSERT INTO a_inventories
VALUES (2419, 8, 28);
INSERT INTO a_inventories
VALUES (2422, 8, 54);
INSERT INTO a_inventories
VALUES (2423, 8, 54);
INSERT INTO a_inventories
VALUES (2424, 8, 28);
INSERT INTO a_inventories
VALUES (2430, 8, 29);
INSERT INTO a_inventories
VALUES (2439, 8, 31);
INSERT INTO a_inventories
VALUES (2449, 8, 8);
INSERT INTO a_inventories
VALUES (2452, 8, 9);
INSERT INTO a_inventories
VALUES (2453, 8, 33);
INSERT INTO a_inventories
VALUES (2457, 8, 34);
INSERT INTO a_inventories
VALUES (2462, 8, 10);
INSERT INTO a_inventories
VALUES (2464, 8, 11);
INSERT INTO a_inventories
VALUES (2467, 8, 11);
INSERT INTO a_inventories
VALUES (2468, 8, 11);
INSERT INTO a_inventories
VALUES (2470, 8, 12);
INSERT INTO a_inventories
VALUES (2471, 8, 12);
INSERT INTO a_inventories
VALUES (2492, 8, 15);
INSERT INTO a_inventories
VALUES (2493, 8, 15);
INSERT INTO a_inventories
VALUES (2494, 8, 15);
INSERT INTO a_inventories
VALUES (2596, 8, 27);
INSERT INTO a_inventories
VALUES (2631, 8, 33);
INSERT INTO a_inventories
VALUES (2638, 8, 48);
INSERT INTO a_inventories
VALUES (2722, 8, 47);
INSERT INTO a_inventories
VALUES (2752, 8, 66);
INSERT INTO a_inventories
VALUES (2779, 8, 56);
INSERT INTO a_inventories
VALUES (2878, 8, 86);
INSERT INTO a_inventories
VALUES (2879, 8, 86);
INSERT INTO a_inventories
VALUES (3000, 8, 128);
INSERT INTO a_inventories
VALUES (3003, 8, 128);
INSERT INTO a_inventories
VALUES (3004, 8, 129);
INSERT INTO a_inventories
VALUES (3054, 8, 137);
INSERT INTO a_inventories
VALUES (3057, 8, 137);
INSERT INTO a_inventories
VALUES (3060, 8, 137);
INSERT INTO a_inventories
VALUES (3061, 8, 138);
INSERT INTO a_inventories
VALUES (3065, 8, 138);
INSERT INTO a_inventories
VALUES (3071, 8, 139);
INSERT INTO a_inventories
VALUES (3072, 8, 139);
INSERT INTO a_inventories
VALUES (3077, 8, 140);
INSERT INTO a_inventories
VALUES (3082, 8, 141);
INSERT INTO a_inventories
VALUES (3083, 8, 141);
INSERT INTO a_inventories
VALUES (3086, 8, 142);
INSERT INTO a_inventories
VALUES (3088, 8, 142);
INSERT INTO a_inventories
VALUES (3090, 8, 142);
INSERT INTO a_inventories
VALUES (3091, 8, 142);
INSERT INTO a_inventories
VALUES (3099, 8, 121);
INSERT INTO a_inventories
VALUES (3108, 8, 122);
INSERT INTO a_inventories
VALUES (3110, 8, 123);
INSERT INTO a_inventories
VALUES (3112, 8, 123);
INSERT INTO a_inventories
VALUES (3117, 8, 124);
INSERT INTO a_inventories
VALUES (3124, 8, 125);
INSERT INTO a_inventories
VALUES (3127, 8, 125);
INSERT INTO a_inventories
VALUES (3129, 8, 126);
INSERT INTO a_inventories
VALUES (3134, 8, 149);
INSERT INTO a_inventories
VALUES (3139, 8, 150);
INSERT INTO a_inventories
VALUES (3140, 8, 150);
INSERT INTO a_inventories
VALUES (3143, 8, 151);
INSERT INTO a_inventories
VALUES (3170, 8, 123);
INSERT INTO a_inventories
VALUES (3171, 8, 124);
INSERT INTO a_inventories
VALUES (3172, 8, 124);
INSERT INTO a_inventories
VALUES (3173, 8, 124);
INSERT INTO a_inventories
VALUES (3175, 8, 124);
INSERT INTO a_inventories
VALUES (3176, 8, 124);
INSERT INTO a_inventories
VALUES (3177, 8, 125);
INSERT INTO a_inventories
VALUES (3189, 8, 121);
INSERT INTO a_inventories
VALUES (3191, 8, 121);
INSERT INTO a_inventories
VALUES (3193, 8, 121);
INSERT INTO a_inventories
VALUES (3204, 8, 137);
INSERT INTO a_inventories
VALUES (3246, 8, 136);
INSERT INTO a_inventories
VALUES (3247, 8, 136);
INSERT INTO a_inventories
VALUES (3248, 8, 136);
INSERT INTO a_inventories
VALUES (3250, 8, 136);
INSERT INTO a_inventories
VALUES (3251, 8, 136);
INSERT INTO a_inventories
VALUES (3252, 8, 137);
INSERT INTO a_inventories
VALUES (3253, 8, 137);
INSERT INTO a_inventories
VALUES (3257, 8, 137);
INSERT INTO a_inventories
VALUES (3258, 8, 137);
INSERT INTO a_inventories
VALUES (3300, 8, 178);
INSERT INTO a_inventories
VALUES (3301, 8, 178);
INSERT INTO a_inventories
VALUES (3331, 8, 183);
INSERT INTO a_inventories
VALUES (3334, 8, 184);
INSERT INTO a_inventories
VALUES (3337, 8, 156);
INSERT INTO a_inventories
VALUES (3350, 8, 160);
INSERT INTO a_inventories
VALUES (3354, 8, 187);
INSERT INTO a_inventories
VALUES (3355, 8, 187);
INSERT INTO a_inventories
VALUES (3359, 8, 188);
INSERT INTO a_inventories
VALUES (3362, 8, 154);
INSERT INTO a_inventories
VALUES (3391, 8, 167);
INSERT INTO a_inventories
VALUES (3400, 8, 194);
INSERT INTO a_inventories
VALUES (3501, 8, 268);
INSERT INTO a_inventories
VALUES (3502, 8, 176);
INSERT INTO a_inventories
VALUES (3503, 8, 177);
INSERT INTO a_inventories
VALUES (1729, 9, 23);
INSERT INTO a_inventories
VALUES (1733, 9, 35);
INSERT INTO a_inventories
VALUES (1734, 9, 35);
INSERT INTO a_inventories
VALUES (1737, 9, 36);
INSERT INTO a_inventories
VALUES (1738, 9, 36);
INSERT INTO a_inventories
VALUES (1739, 9, 36);
INSERT INTO a_inventories
VALUES (1740, 9, 36);
INSERT INTO a_inventories
VALUES (1742, 9, 36);
INSERT INTO a_inventories
VALUES (1745, 9, 37);
INSERT INTO a_inventories
VALUES (1748, 9, 37);
INSERT INTO a_inventories
VALUES (1749, 9, 37);
INSERT INTO a_inventories
VALUES (1750, 9, 38);
INSERT INTO a_inventories
VALUES (1755, 9, 41);
INSERT INTO a_inventories
VALUES (1763, 9, 3);
INSERT INTO a_inventories
VALUES (1768, 9, 3);
INSERT INTO a_inventories
VALUES (1769, 9, 3);
INSERT INTO a_inventories
VALUES (1770, 9, 4);
INSERT INTO a_inventories
VALUES (1772, 9, 4);
INSERT INTO a_inventories
VALUES (1781, 9, 5);
INSERT INTO a_inventories
VALUES (1787, 9, 6);
INSERT INTO a_inventories
VALUES (1788, 9, 6);
INSERT INTO a_inventories
VALUES (1791, 9, 7);
INSERT INTO a_inventories
VALUES (1792, 9, 7);
INSERT INTO a_inventories
VALUES (1797, 9, 8);
INSERT INTO a_inventories
VALUES (1912, 9, 6);
INSERT INTO a_inventories
VALUES (1940, 9, 0);
INSERT INTO a_inventories
VALUES (2058, 9, 33);
INSERT INTO a_inventories
VALUES (2243, 9, 32);
INSERT INTO a_inventories
VALUES (2245, 9, 33);
INSERT INTO a_inventories
VALUES (2255, 9, 34);
INSERT INTO a_inventories
VALUES (2257, 9, 34);
INSERT INTO a_inventories
VALUES (2259, 9, 35);
INSERT INTO a_inventories
VALUES (2260, 9, 35);
INSERT INTO a_inventories
VALUES (2261, 9, 35);
INSERT INTO a_inventories
VALUES (2262, 9, 35);
INSERT INTO a_inventories
VALUES (2264, 9, 27);
INSERT INTO a_inventories
VALUES (2266, 9, 27);
INSERT INTO a_inventories
VALUES (2270, 9, 28);
INSERT INTO a_inventories
VALUES (2274, 9, 29);
INSERT INTO a_inventories
VALUES (2276, 9, 29);
INSERT INTO a_inventories
VALUES (2278, 9, 29);
INSERT INTO a_inventories
VALUES (2302, 9, 33);
INSERT INTO a_inventories
VALUES (2316, 9, 35);
INSERT INTO a_inventories
VALUES (2319, 9, 7);
INSERT INTO a_inventories
VALUES (2322, 9, 8);
INSERT INTO a_inventories
VALUES (2323, 9, 8);
INSERT INTO a_inventories
VALUES (2326, 9, 22);
INSERT INTO a_inventories
VALUES (2340, 9, 32);
INSERT INTO a_inventories
VALUES (2359, 9, 3);
INSERT INTO a_inventories
VALUES (2365, 9, 36);
INSERT INTO a_inventories
VALUES (2370, 9, 5);
INSERT INTO a_inventories
VALUES (2373, 9, 6);
INSERT INTO a_inventories
VALUES (2374, 9, 6);
INSERT INTO a_inventories
VALUES (2375, 9, 6);
INSERT INTO a_inventories
VALUES (2377, 9, 6);
INSERT INTO a_inventories
VALUES (2378, 9, 6);
INSERT INTO a_inventories
VALUES (2380, 9, 7);
INSERT INTO a_inventories
VALUES (2387, 9, 8);
INSERT INTO a_inventories
VALUES (2394, 9, 9);
INSERT INTO a_inventories
VALUES (2395, 9, 9);
INSERT INTO a_inventories
VALUES (2396, 9, 9);
INSERT INTO a_inventories
VALUES (2402, 9, 10);
INSERT INTO a_inventories
VALUES (2403, 9, 10);
INSERT INTO a_inventories
VALUES (2404, 9, 10);
INSERT INTO a_inventories
VALUES (2406, 9, 11);
INSERT INTO a_inventories
VALUES (2408, 9, 11);
INSERT INTO a_inventories
VALUES (2409, 9, 11);
INSERT INTO a_inventories
VALUES (2410, 9, 11);
INSERT INTO a_inventories
VALUES (2411, 9, 12);
INSERT INTO a_inventories
VALUES (2414, 9, 12);
INSERT INTO a_inventories
VALUES (2415, 9, 12);
INSERT INTO a_inventories
VALUES (2418, 9, 13);
INSERT INTO a_inventories
VALUES (2419, 9, 13);
INSERT INTO a_inventories
VALUES (2424, 9, 14);
INSERT INTO a_inventories
VALUES (2430, 9, 15);
INSERT INTO a_inventories
VALUES (2439, 9, 16);
INSERT INTO a_inventories
VALUES (2453, 9, 18);
INSERT INTO a_inventories
VALUES (2457, 9, 19);
INSERT INTO a_inventories
VALUES (2596, 9, 15);
INSERT INTO a_inventories
VALUES (2631, 9, 21);
INSERT INTO a_inventories
VALUES (2638, 9, 36);
INSERT INTO a_inventories
VALUES (2722, 9, 35);
INSERT INTO a_inventories
VALUES (2752, 9, 54);
INSERT INTO a_inventories
VALUES (2878, 9, 74);
INSERT INTO a_inventories
VALUES (2879, 9, 74);
INSERT INTO a_inventories
VALUES (3000, 9, 110);
INSERT INTO a_inventories
VALUES (3003, 9, 111);
INSERT INTO a_inventories
VALUES (3004, 9, 111);
INSERT INTO a_inventories
VALUES (3054, 9, 119);
INSERT INTO a_inventories
VALUES (3057, 9, 119);
INSERT INTO a_inventories
VALUES (3060, 9, 120);
INSERT INTO a_inventories
VALUES (3061, 9, 120);
INSERT INTO a_inventories
VALUES (3065, 9, 121);
INSERT INTO a_inventories
VALUES (3071, 9, 122);
INSERT INTO a_inventories
VALUES (3072, 9, 122);
INSERT INTO a_inventories
VALUES (3077, 9, 122);
INSERT INTO a_inventories
VALUES (3082, 9, 123);
INSERT INTO a_inventories
VALUES (3083, 9, 123);
INSERT INTO a_inventories
VALUES (3086, 9, 124);
INSERT INTO a_inventories
VALUES (3088, 9, 124);
INSERT INTO a_inventories
VALUES (3090, 9, 125);
INSERT INTO a_inventories
VALUES (3091, 9, 125);
INSERT INTO a_inventories
VALUES (3099, 9, 109);
INSERT INTO a_inventories
VALUES (3108, 9, 110);
INSERT INTO a_inventories
VALUES (3110, 9, 111);
INSERT INTO a_inventories
VALUES (3112, 9, 111);
INSERT INTO a_inventories
VALUES (3117, 9, 112);
INSERT INTO a_inventories
VALUES (3124, 9, 113);
INSERT INTO a_inventories
VALUES (3127, 9, 113);
INSERT INTO a_inventories
VALUES (3129, 9, 114);
INSERT INTO a_inventories
VALUES (3134, 9, 134);
INSERT INTO a_inventories
VALUES (3139, 9, 135);
INSERT INTO a_inventories
VALUES (3140, 9, 135);
INSERT INTO a_inventories
VALUES (3143, 9, 136);
INSERT INTO a_inventories
VALUES (3189, 9, 109);
INSERT INTO a_inventories
VALUES (3191, 9, 109);
INSERT INTO a_inventories
VALUES (3193, 9, 109);
INSERT INTO a_inventories
VALUES (3204, 9, 125);
INSERT INTO a_inventories
VALUES (3300, 9, 161);
INSERT INTO a_inventories
VALUES (3301, 9, 161);
INSERT INTO a_inventories
VALUES (3331, 9, 165);
INSERT INTO a_inventories
VALUES (3334, 9, 166);
INSERT INTO a_inventories
VALUES (3350, 9, 148);
INSERT INTO a_inventories
VALUES (3354, 9, 169);
INSERT INTO a_inventories
VALUES (3355, 9, 169);
INSERT INTO a_inventories
VALUES (3359, 9, 170);
INSERT INTO a_inventories
VALUES (3391, 9, 155);
INSERT INTO a_inventories
VALUES (3400, 9, 179);

commit;

rem
rem Header: oe_p_ord.sql 09-jan-01
rem
rem Copyright (c) 2001 Oracle Corporation.  All rights reserved.
rem
rem Owner  : ahunold
rem
rem NAME
rem   oe_p_ord.sql - populate OE Common Schema
rem
rem DESCRIPTON
rem   Table A_orders
rem
rem MODIFIED   (MM/DD/YY)
rem   ahunold   07/
25/
01 - timestamp.
rem   ahunold   01/
30/
01 - OE script headers
rem   ahunold   01/
24/
01 - Eliminate extra lines from last merge
rem   ahunold   01/
09/
01 - checkin ADE

INSERT INTO A_orders
VALUES (2458, TO_DATE('16- AUG-20', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 721, 0, 78279.6, 153, NULL);
INSERT INTO A_orders
VALUES (2397, TO_DATE('19-NOV-20', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 727, 1, 42283.2, 154, NULL);
INSERT INTO A_orders
VALUES (2454, TO_DATE('02-OCT-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 729, 1, 6653.4, 154, NULL);
INSERT INTO A_orders
VALUES (2354, TO_DATE('14-JUL-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 755, 0, 46257, 155, NULL);
INSERT INTO A_orders
VALUES (2358, TO_DATE('08-JAN-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 766, 2, 7826, 155, NULL);
INSERT INTO A_orders
VALUES (2381, TO_DATE('14-MAY-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 767, 3, 23034.6, 156, NULL);
INSERT INTO A_orders
VALUES (2440, TO_DATE('31-AUG-20', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 107, 3, 70576.9, 156, NULL);
INSERT INTO A_orders
VALUES (2357, TO_DATE('08-JAN-19', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 108, 5, 59872.4, 158, NULL);
INSERT INTO A_orders
VALUES (2394, TO_DATE('10-FEB-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 109, 5, 21863, 158, NULL);
INSERT INTO A_orders
VALUES (2435, TO_DATE('02-SEP-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 144, 6, 62303, 159, NULL);
INSERT INTO A_orders
VALUES (2455, TO_DATE('20-SEP-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 145, 7, 14087.5, 160, NULL);
INSERT INTO A_orders
VALUES (2379, TO_DATE('16-MAY-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 146, 8, 17848.2, 161, NULL);
INSERT INTO A_orders
VALUES (2396, TO_DATE('02-FEB-19', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 147, 8, 34930, 161, NULL);
INSERT INTO A_orders
VALUES (2406, TO_DATE('29-JUN-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 148, 8, 2854.2, 161, NULL);
INSERT INTO A_orders
VALUES (2434, TO_DATE('13-SEP-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 149, 8, 268651.8, 161, NULL);
INSERT INTO A_orders
VALUES (2436, TO_DATE('02-SEP-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 116, 8, 6394.8, 161, NULL);
INSERT INTO A_orders
VALUES (2446, TO_DATE('27-JUL-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 117, 8, 103679.3, 161, NULL);
INSERT INTO A_orders
VALUES (2447, TO_DATE('27-JUL-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 101, 8, 33893.6, 161, NULL);
INSERT INTO A_orders
VALUES (2432, TO_DATE('14-SEP-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 102, 10, 10523, 163, NULL);
INSERT INTO A_orders
VALUES (2433, TO_DATE('13-SEP-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 103, 10, 78, 163, NULL);
INSERT INTO A_orders
VALUES (2355, TO_DATE('26-JAN-19', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 104, 8, 94513.5, NULL, NULL);
INSERT INTO A_orders
VALUES (2356, TO_DATE('26-JAN-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 105, 5, 29473.8, NULL, NULL);
INSERT INTO A_orders
VALUES (2359, TO_DATE('08-JAN-19', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 106, 9, 5543.1, NULL, NULL);
INSERT INTO A_orders
VALUES (2360, TO_DATE('14-NOV-20', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 107, 4, 990.4, NULL, NULL);
INSERT INTO A_orders
VALUES (2361, TO_DATE('13-NOV-20', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 108, 8, 120131.3, NULL, NULL);
INSERT INTO A_orders
VALUES (2362, TO_DATE('13-NOV-20', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 109, 4, 92829.4, NULL, NULL);
INSERT INTO A_orders
VALUES (2363, TO_DATE('23-OCT-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 144, 0, 10082.3, NULL, NULL);
INSERT INTO A_orders
VALUES (2364, TO_DATE('28-AUG-20', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 145, 4, 9500, NULL, NULL);
INSERT INTO A_orders
VALUES (2365, TO_DATE('28-AUG-20', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 146, 9, 27455.3, NULL, NULL);
INSERT INTO A_orders
VALUES (2366, TO_DATE('28-AUG-20', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 147, 5, 37319.4, NULL, NULL);
INSERT INTO A_orders
VALUES (2367, TO_DATE('27-JUN-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 148, 10, 144054.8, NULL, NULL);
INSERT INTO A_orders
VALUES (2368, TO_DATE('26-JUN-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 149, 10, 60065, NULL, NULL);
INSERT INTO A_orders
VALUES (2369, TO_DATE('26-JUN-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 116, 0, 11097.4, NULL, NULL);
INSERT INTO A_orders
VALUES (2370, TO_DATE('26-JUN-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 117, 4, 126, NULL, NULL);
INSERT INTO A_orders
VALUES (2371, TO_DATE('16-MAY-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 118, 6, 79405.6, NULL, NULL);
INSERT INTO A_orders
VALUES (2372, TO_DATE('27-FEB-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 119, 9, 16447.2, NULL, NULL);
INSERT INTO A_orders
VALUES (2373, TO_DATE('27-FEB-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 120, 4, 416, NULL, NULL);
INSERT INTO A_orders
VALUES (2374, TO_DATE('27-FEB-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 121, 0, 4797, NULL, NULL);
INSERT INTO A_orders
VALUES (2375, TO_DATE('26-FEB-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 122, 2, 103834.4, NULL, NULL);
INSERT INTO A_orders
VALUES (2376, TO_DATE('07-JUN-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 123, 6, 11006.2, NULL, NULL);
INSERT INTO A_orders
VALUES (2377, TO_DATE('07-JUN-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 141, 5, 38217.8, NULL, NULL);
INSERT INTO A_orders
VALUES (2378, TO_DATE('24-MAY-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 142, 5, 25691.3, NULL, NULL);
INSERT INTO A_orders
VALUES (2380, TO_DATE('16-MAY-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 143, 3, 27132.6, NULL, NULL);
INSERT INTO A_orders
VALUES (2382, TO_DATE('14-MAY-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 144, 8, 71173, NULL, NULL);
INSERT INTO A_orders
VALUES (2383, TO_DATE('12-MAY-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 145, 8, 36374.7, NULL, NULL);
INSERT INTO A_orders
VALUES (2384, TO_DATE('12-MAY-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 146, 3, 29249.1, NULL, NULL);
INSERT INTO A_orders
VALUES (2385, TO_DATE('28-OCT-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 147, 4, 295892, NULL, NULL);
INSERT INTO A_orders
VALUES (2386, TO_DATE('02-NOV-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 148, 10, 21116.9, NULL, NULL);
INSERT INTO A_orders
VALUES (2387, TO_DATE('11-MAR-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 149, 5, 52758.9, NULL, NULL);
INSERT INTO A_orders
VALUES (2388, TO_DATE('04-JUN-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 150, 4, 282694.3, NULL, NULL);
INSERT INTO A_orders
VALUES (2389, TO_DATE('04-JUN-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 151, 4, 17620, NULL, NULL);
INSERT INTO A_orders
VALUES (2390, TO_DATE('18-NOV-20', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'online', 152, 9, 7616.8, NULL, NULL);
INSERT INTO A_orders
VALUES (2391, TO_DATE('27-FEB-19', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 153, 2, 48070.6, 156, NULL);
INSERT INTO A_orders
VALUES (2392, TO_DATE('21-JUL-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 154, 9, 26632, 161, NULL);
INSERT INTO A_orders
VALUES (2393, TO_DATE('10-FEB-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 155, 4, 23431.9, 161, NULL);
INSERT INTO A_orders
VALUES (2395, TO_DATE('02-FEB-19', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 156, 3, 68501, 163, NULL);
INSERT INTO A_orders
VALUES (2398, TO_DATE('19-NOV-20', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 157, 9, 7110.3, 163, NULL);
INSERT INTO A_orders
VALUES (2399, TO_DATE('19-NOV-20', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 158, 0, 25270.3, 161, NULL);
INSERT INTO A_orders
VALUES (2400, TO_DATE('10-JUL-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 159, 2, 69286.4, 161, NULL);
INSERT INTO A_orders
VALUES (2401, TO_DATE('10-JUL-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 160, 3, 969.2, 163, NULL);
INSERT INTO A_orders
VALUES (2402, TO_DATE('02-JUL-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 161, 8, 600, 154, NULL);
INSERT INTO A_orders
VALUES (2403, TO_DATE('01-JUL-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 162, 0, 220, 154, NULL);
INSERT INTO A_orders
VALUES (2404, TO_DATE('01-JUL-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 163, 6, 510, 158, NULL);
INSERT INTO A_orders
VALUES (2405, TO_DATE('01-JUL-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 164, 5, 1233, 159, NULL);
INSERT INTO A_orders
VALUES (2407, TO_DATE('29-JUN-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 165, 9, 2519, 155, NULL);
INSERT INTO A_orders
VALUES (2408, TO_DATE('29-JUN-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 166, 1, 309, 158, NULL);
INSERT INTO A_orders
VALUES (2409, TO_DATE('29-JUN-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 167, 2, 48, 154, NULL);
INSERT INTO A_orders
VALUES (2410, TO_DATE('24-MAY-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 168, 6, 45175, 156, NULL);
INSERT INTO A_orders
VALUES (2411, TO_DATE('24-MAY-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 169, 8, 15760.5, 156, NULL);
INSERT INTO A_orders
VALUES (2412, TO_DATE('29-MAR-19', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 170, 9, 66816, 158, NULL);
INSERT INTO A_orders
VALUES (2413, TO_DATE('29-MAR-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 101, 5, 48552, 161, NULL);
INSERT INTO A_orders
VALUES (2414, TO_DATE('29-MAR-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 102, 8, 10794.6, 153, NULL);
INSERT INTO A_orders
VALUES (2415, TO_DATE('29-MAR-97', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 103, 6, 310, 161, NULL);
INSERT INTO A_orders
VALUES (2416, TO_DATE('29-MAR-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 104, 6, 384, 160, NULL);
INSERT INTO A_orders
VALUES (2417, TO_DATE('20-MAR-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 105, 5, 1926.6, 163, NULL);
INSERT INTO A_orders
VALUES (2418, TO_DATE('20-MAR-20', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 106, 4, 5546.6, 163, NULL);
INSERT INTO A_orders
VALUES (2419, TO_DATE('20-MAR-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 107, 3, 31574, 160, NULL);
INSERT INTO A_orders
VALUES (2420, TO_DATE('13-MAR-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 108, 2, 29750, 160, NULL);
INSERT INTO A_orders
VALUES (2421, TO_DATE('12-MAR-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 109, 1, 72836, NULL, NULL);
INSERT INTO A_orders
VALUES (2422, TO_DATE('04-NOV-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 144, 2, 11188.5, 153, NULL);
INSERT INTO A_orders
VALUES (2423, TO_DATE('21-NOV-20', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 145, 3, 10367.7, 160, NULL);
INSERT INTO A_orders
VALUES (2424, TO_DATE('21-NOV-20', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 146, 4, 13824, 153, NULL);
INSERT INTO A_orders
VALUES (2425, TO_DATE('17-NOV-19', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 147, 5, 1500.8, 163, NULL);
INSERT INTO A_orders
VALUES (2426, TO_DATE('17-NOV-19', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 148, 6, 7200, NULL, NULL);
INSERT INTO A_orders
VALUES (2427, TO_DATE('10-NOV-20', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 149, 7, 9055, 163, NULL);
INSERT INTO A_orders
VALUES (2428, TO_DATE('10-NOV-20', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 116, 8, 14685.8, NULL, NULL);
INSERT INTO A_orders
VALUES (2429, TO_DATE('10-NOV-20', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 117, 9, 52125, 154, NULL);
INSERT INTO A_orders
VALUES (2430, TO_DATE('02-OCT-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 101, 8, 29669.9, 159, NULL);
INSERT INTO A_orders
VALUES (2431, TO_DATE('14-SEP-19', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 102, 1, 5610.6, 163, NULL);
INSERT INTO A_orders
VALUES (2437, TO_DATE('01-SEP-19', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 103, 4, 13550, 163, NULL);
INSERT INTO A_orders
VALUES (2438, TO_DATE('01-SEP-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 104, 0, 5451, 154, NULL);
INSERT INTO A_orders
VALUES (2439, TO_DATE('31-AUG-20', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 105, 1, 22150.1, 159, NULL);
INSERT INTO A_orders
VALUES (2441, TO_DATE('01-AUG-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 106, 5, 2075.2, 160, NULL);
INSERT INTO A_orders
VALUES (2442, TO_DATE('27-JUL-19', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 107, 9, 52471.9, 154, NULL);
INSERT INTO A_orders
VALUES (2443, TO_DATE('27-JUL-19', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 108, 0, 3646, 154, NULL);
INSERT INTO A_orders
VALUES (2444, TO_DATE('27-JUL-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 109, 1, 77727.2, 155, NULL);
INSERT INTO A_orders
VALUES (2445, TO_DATE('27-JUL-19', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 144, 8, 5537.8, 158, NULL);
INSERT INTO A_orders
VALUES (2448, TO_DATE('18-JUN-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 145, 5, 1388, 158, NULL);
INSERT INTO A_orders
VALUES (2449, TO_DATE('13-JUN-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 146, 6, 86, 155, NULL);
INSERT INTO A_orders
VALUES (2450, TO_DATE('11-APR-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 147, 3, 1636, 159, NULL);
INSERT INTO A_orders
VALUES (2451, TO_DATE('17-OCT-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 148, 7, 10474.6, 154, NULL);
INSERT INTO A_orders
VALUES (2452, TO_DATE('06-OCT-21', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 149, 5, 12589, 159, NULL);
INSERT INTO A_orders
VALUES (2453, TO_DATE('04-OCT-01', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 116, 0, 129, 153, NULL);
INSERT INTO A_orders
VALUES (2456, TO_DATE('07-NOV-19', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 117, 0, 3878.4, 163, NULL);
INSERT INTO A_orders
VALUES (2457, TO_DATE('31-OCT-01', 'DD-MON-RR', 'NLS_DATE_LANGUAGE=American'), 'direct', 118, 5, 21586.2, 159, NULL);



REM ===================================================================
REM correction: onlide A_orders don't have a sales_rep_id
REM ===================================================================

UPDATE A_orders
SET    sales_rep_id = NULL
WHERE  order_mode = 'online';

COMMIT;

rem
rem Header: oe_p_itm.sql 09-jan-01
rem
rem Copyright (c) 2001 Oracle Corporation.  All rights reserved.
rem
rem Owner  : ahunold
rem
rem NAME
rem   oe_p_itm.sql - populate OE Common Schema
rem
rem DESCRIPTON
rem   Table A_order_items
rem
rem MODIFIED   (MM/DD/YY)
rem   ahunold   01/09/01 - checkin ADE

INSERT INTO A_order_items VALUES (2355, 1,2289,    46,200); 
INSERT INTO A_order_items VALUES (2356, 1,2264, 199.1, 38); 
INSERT INTO A_order_items VALUES (2357, 1,2211,   3.3,140); 
INSERT INTO A_order_items VALUES (2358, 1,1781, 226.6,  9); 
INSERT INTO A_order_items VALUES (2359, 1,2337, 270.6,  1); 
INSERT INTO A_order_items VALUES (2360, 1,2058,    23, 29); 
INSERT INTO A_order_items VALUES (2361, 1,2289,    46,180); 
INSERT INTO A_order_items VALUES (2362, 1,2289,    48,200); 
INSERT INTO A_order_items VALUES (2363, 1,2264, 199.1,  9); 
INSERT INTO A_order_items VALUES (2364, 1,1910,    14,  6);
INSERT INTO A_order_items VALUES (2365, 1,2289,    48, 92); 
INSERT INTO A_order_items VALUES (2366, 1,2359, 226.6,  8); 
INSERT INTO A_order_items VALUES (2367, 1,2289,    48, 99); 
INSERT INTO A_order_items VALUES (2354, 1,3106,    48, 61); 
INSERT INTO A_order_items VALUES (2368, 1,3106,    48,150); 
INSERT INTO A_order_items VALUES (2369, 1,3150,    18,  3);
INSERT INTO A_order_items VALUES (2370, 1,1910,    14,  9);
INSERT INTO A_order_items VALUES (2371, 1,2274,   157,  6); 
INSERT INTO A_order_items VALUES (2372, 1,3106,    48,  6);
INSERT INTO A_order_items VALUES (2373, 1,1820,    49,  8);
INSERT INTO A_order_items VALUES (2374, 1,2422,   150, 10); 
INSERT INTO A_order_items VALUES (2375, 1,3106,    42,140); 
INSERT INTO A_order_items VALUES (2376, 1,2270,    60, 14); 
INSERT INTO A_order_items VALUES (2377, 1,2289,    42,130); 
INSERT INTO A_order_items VALUES (2378, 1,2403, 113.3, 20); 
INSERT INTO A_order_items VALUES (2379, 1,3106,    42, 92); 
INSERT INTO A_order_items VALUES (2380, 1,3106,    42, 26); 
INSERT INTO A_order_items VALUES (2381, 1,3117,    38,110); 
INSERT INTO A_order_items VALUES (2382, 1,3106,    42,160); 
INSERT INTO A_order_items VALUES (2383, 1,2409, 194.7, 37); 
INSERT INTO A_order_items VALUES (2384, 1,2289,    43, 95); 
INSERT INTO A_order_items VALUES (2385, 1,2289,    43,200); 
INSERT INTO A_order_items VALUES (2386, 1,2330,   1.1,  7); 
INSERT INTO A_order_items VALUES (2387, 1,2211,   3.3, 52); 
INSERT INTO A_order_items VALUES (2388, 1,2289,    43,150); 
INSERT INTO A_order_items VALUES (2389, 1,3106,    43,180); 
INSERT INTO A_order_items VALUES (2390, 1,1910,    14,  4);
INSERT INTO A_order_items VALUES (2391, 1,1787,   101,  5); 
INSERT INTO A_order_items VALUES (2392, 1,3106,    43, 63); 
INSERT INTO A_order_items VALUES (2393, 1,3051,    12, 10); 
INSERT INTO A_order_items VALUES (2394, 1,3117,    41, 90); 
INSERT INTO A_order_items VALUES (2395, 1,2211,   3.3,110); 
INSERT INTO A_order_items VALUES (2396, 1,3106,    44,150); 
INSERT INTO A_order_items VALUES (2397, 1,2976,    52,  2);
INSERT INTO A_order_items VALUES (2398, 1,2471, 482.9,  5); 
INSERT INTO A_order_items VALUES (2399, 1,2289,    44,120); 
INSERT INTO A_order_items VALUES (2400, 1,2976,    52,  4);
INSERT INTO A_order_items VALUES (2401, 1,2492,    41,  4);
INSERT INTO A_order_items VALUES (2402, 1,2536,    75,  8);
INSERT INTO A_order_items VALUES (2403, 1,2522,    44,  5);
INSERT INTO A_order_items VALUES (2404, 1,2721,    85,  6);
INSERT INTO A_order_items VALUES (2405, 1,2638,   137,  9); 
INSERT INTO A_order_items VALUES (2406, 1,2721,    85,  5);
INSERT INTO A_order_items VALUES (2407, 1,2721,    85,  5);
INSERT INTO A_order_items VALUES (2408, 1,2751,    61,  3);
INSERT INTO A_order_items VALUES (2409, 1,2810,     6,  8); 
INSERT INTO A_order_items VALUES (2410, 1,2976,    46, 10); 
INSERT INTO A_order_items VALUES (2411, 1,3082,    81,  2);
INSERT INTO A_order_items VALUES (2412, 1,3106,    46,170); 
INSERT INTO A_order_items VALUES (2413, 1,3108,    77,200); 
INSERT INTO A_order_items VALUES (2414, 1,3208,   1.1,  8); 
INSERT INTO A_order_items VALUES (2415, 1,2751,    62,  5);
INSERT INTO A_order_items VALUES (2416, 1,2870,   4.4, 10); 
INSERT INTO A_order_items VALUES (2417, 1,2870,   4.4,  9); 
INSERT INTO A_order_items VALUES (2418, 1,3082,    75, 15); 
INSERT INTO A_order_items VALUES (2419, 1,3106,    46,150); 
INSERT INTO A_order_items VALUES (2420, 1,3106,    46,110); 
INSERT INTO A_order_items VALUES (2421, 1,3106,    46,160); 
INSERT INTO A_order_items VALUES (2422, 1,3106,    46, 18); 
INSERT INTO A_order_items VALUES (2423, 1,3220,    39,  8);
INSERT INTO A_order_items VALUES (2424, 1,3350,   693, 11); 
INSERT INTO A_order_items VALUES (2425, 1,3501, 492.8,  3); 
INSERT INTO A_order_items VALUES (2426, 1,3193,   2.2,  6); 
INSERT INTO A_order_items VALUES (2427, 1,2430,   173, 12); 
INSERT INTO A_order_items VALUES (2428, 1,3106,    42,  7);
INSERT INTO A_order_items VALUES (2429, 1,3106,    42,200); 
INSERT INTO A_order_items VALUES (2430, 1,3350,   693,  6); 
INSERT INTO A_order_items VALUES (2431, 1,3097,   2.2,  3); 
INSERT INTO A_order_items VALUES (2432, 1,2976,    49,  3);
INSERT INTO A_order_items VALUES (2433, 1,1910,    13,  6);
INSERT INTO A_order_items VALUES (2434, 1,2211,   3.3, 81); 
INSERT INTO A_order_items VALUES (2435, 1,2289,    48, 35); 
INSERT INTO A_order_items VALUES (2436, 1,3208,   1.1,  8); 
INSERT INTO A_order_items VALUES (2437, 1,2423,    83,  8);
INSERT INTO A_order_items VALUES (2438, 1,2995,    69,  3);
INSERT INTO A_order_items VALUES (2439, 1,1797, 316.8,  9); 
INSERT INTO A_order_items VALUES (2440, 1,2289,    48, 19); 
INSERT INTO A_order_items VALUES (2441, 1,2536,    80,  9);
INSERT INTO A_order_items VALUES (2442, 1,2402,   127, 26); 
INSERT INTO A_order_items VALUES (2443, 1,3106,    44,  3);
INSERT INTO A_order_items VALUES (2444, 1,3117,    36,110); 
INSERT INTO A_order_items VALUES (2445, 1,2270,    66,  5);
INSERT INTO A_order_items VALUES (2446, 1,2289,    48, 47); 
INSERT INTO A_order_items VALUES (2447, 1,2264, 199.1, 29); 
INSERT INTO A_order_items VALUES (2448, 1,3106,    44,  3);
INSERT INTO A_order_items VALUES (2449, 1,2522,    43,  2);
INSERT INTO A_order_items VALUES (2450, 1,3191,   1.1,  4); 
INSERT INTO A_order_items VALUES (2451, 1,1910,    13,  9);
INSERT INTO A_order_items VALUES (2452, 1,3117,    38,140); 
INSERT INTO A_order_items VALUES (2453, 1,2492,    43,  3);
INSERT INTO A_order_items VALUES (2454, 1,2289,    43,120); 
INSERT INTO A_order_items VALUES (2455, 1,2471, 482.9,  3); 
INSERT INTO A_order_items VALUES (2456, 1,2522,    40,  5);
INSERT INTO A_order_items VALUES (2457, 1,3108,    72, 36); 
INSERT INTO A_order_items VALUES (2458, 1,3117,    38,140); 
INSERT INTO A_order_items VALUES (2354, 2,3114,  96.8, 43); 
INSERT INTO A_order_items VALUES (2356, 2,2274, 148.5, 34); 
INSERT INTO A_order_items VALUES (2358, 2,1782,   125,  4); 
INSERT INTO A_order_items VALUES (2361, 2,2299,    76,180); 
INSERT INTO A_order_items VALUES (2362, 2,2299,    76,160); 
INSERT INTO A_order_items VALUES (2363, 2,2272,   129,  7); 
INSERT INTO A_order_items VALUES (2365, 2,2293,    99, 28); 
INSERT INTO A_order_items VALUES (2368, 2,3110,    42, 60); 
INSERT INTO A_order_items VALUES (2369, 2,3155,    43,  1);
INSERT INTO A_order_items VALUES (2372, 2,3108,    74,  2);
INSERT INTO A_order_items VALUES (2373, 2,1825,    24,  1);
INSERT INTO A_order_items VALUES (2374, 2,2423,    78,  6);
INSERT INTO A_order_items VALUES (2375, 2,3112,    71, 84); 
INSERT INTO A_order_items VALUES (2376, 2,2276, 236.5,  4); 
INSERT INTO A_order_items VALUES (2378, 2,2412,    95,  2);
INSERT INTO A_order_items VALUES (2380, 2,3108,    75, 18); 
INSERT INTO A_order_items VALUES (2381, 2,3124,    77, 44); 
INSERT INTO A_order_items VALUES (2382, 2,3110,    43, 64); 
INSERT INTO A_order_items VALUES (2384, 2,2299,    71, 48); 
INSERT INTO A_order_items VALUES (2386, 2,2334,   3.3,  5); 
INSERT INTO A_order_items VALUES (2388, 2,2293,    94, 90); 
INSERT INTO A_order_items VALUES (2389, 2,3112,    73, 18); 
INSERT INTO A_order_items VALUES (2390, 2,1912,    14,  2);
INSERT INTO A_order_items VALUES (2391, 2,1791, 262.9,  3); 
INSERT INTO A_order_items VALUES (2392, 2,3112,    73, 57); 
INSERT INTO A_order_items VALUES (2393, 2,3060,   295,  2); 
INSERT INTO A_order_items VALUES (2394, 2,3123,    77, 36); 
INSERT INTO A_order_items VALUES (2396, 2,3108,    76, 75); 
INSERT INTO A_order_items VALUES (2399, 2,2293,    94, 12); 
INSERT INTO A_order_items VALUES (2400, 2,2982,    41,  1);
INSERT INTO A_order_items VALUES (2401, 2,2496, 268.4,  3); 
INSERT INTO A_order_items VALUES (2406, 2,2725,   3.3,  4); 
INSERT INTO A_order_items VALUES (2408, 2,2761,    26,  1);
INSERT INTO A_order_items VALUES (2411, 2,3086,   208,  2); 
INSERT INTO A_order_items VALUES (2412, 2,3114,    98, 68); 
INSERT INTO A_order_items VALUES (2413, 2,3112,    75, 40); 
INSERT INTO A_order_items VALUES (2414, 2,3216,    30,  7);
INSERT INTO A_order_items VALUES (2416, 2,2878,   340,  1); 
INSERT INTO A_order_items VALUES (2418, 2,3090,   187, 12); 
INSERT INTO A_order_items VALUES (2419, 2,3114,    99, 45); 
INSERT INTO A_order_items VALUES (2420, 2,3110,    46, 11); 
INSERT INTO A_order_items VALUES (2421, 2,3108,    78,160); 
INSERT INTO A_order_items VALUES (2422, 2,3117,    41,  5);
INSERT INTO A_order_items VALUES (2423, 2,3224,    32,  3);
INSERT INTO A_order_items VALUES (2424, 2,3354,   541,  9); 
INSERT INTO A_order_items VALUES (2425, 2,3511,     9,  2); 
INSERT INTO A_order_items VALUES (2427, 2,2439,   121,  1); 
INSERT INTO A_order_items VALUES (2428, 2,3108,    76,  1);
INSERT INTO A_order_items VALUES (2429, 2,3108,    76, 40); 
INSERT INTO A_order_items VALUES (2430, 2,3353, 454.3,  5); 
INSERT INTO A_order_items VALUES (2431, 2,3106,    48,  1);
INSERT INTO A_order_items VALUES (2432, 2,2982,    43,  2);
INSERT INTO A_order_items VALUES (2435, 2,2299,    75,  4);
INSERT INTO A_order_items VALUES (2436, 2,3209,    13,  2);
INSERT INTO A_order_items VALUES (2437, 2,2430, 157.3,  4); 
INSERT INTO A_order_items VALUES (2438, 2,3000,  1748,  3); 
INSERT INTO A_order_items VALUES (2439, 2,1806,    45,  4);
INSERT INTO A_order_items VALUES (2440, 2,2293,    98,  2);
INSERT INTO A_order_items VALUES (2441, 2,2537, 193.6,  7); 
INSERT INTO A_order_items VALUES (2442, 2,2410, 350.9, 21); 
INSERT INTO A_order_items VALUES (2443, 2,3114,   101,  2); 
INSERT INTO A_order_items VALUES (2444, 2,3127, 488.4, 88); 
INSERT INTO A_order_items VALUES (2445, 2,2278,    49,  3);
INSERT INTO A_order_items VALUES (2447, 2,2266,   297, 23); 
INSERT INTO A_order_items VALUES (2448, 2,3114,    99,  0);
INSERT INTO A_order_items VALUES (2450, 2,3193,   2.2,  3); 
INSERT INTO A_order_items VALUES (2454, 2,2293,    99,  0);
INSERT INTO A_order_items VALUES (2457, 2,3123,    79, 14); 
INSERT INTO A_order_items VALUES (2458, 2,3123,    79,112); 
INSERT INTO A_order_items VALUES (2354, 3,3123,    79, 47); 
INSERT INTO A_order_items VALUES (2361, 3,2308,    53,182); 
INSERT INTO A_order_items VALUES (2362, 3,2311,    93,164); 
INSERT INTO A_order_items VALUES (2365, 3,2302, 133.1, 29); 
INSERT INTO A_order_items VALUES (2368, 3,3117,    38, 62); 
INSERT INTO A_order_items VALUES (2369, 3,3163,    32,  5);
INSERT INTO A_order_items VALUES (2372, 3,3110,    42,  7);
INSERT INTO A_order_items VALUES (2375, 3,3117,    38, 85); 
INSERT INTO A_order_items VALUES (2378, 3,2414, 438.9,  7); 
INSERT INTO A_order_items VALUES (2380, 3,3117,    38, 23); 
INSERT INTO A_order_items VALUES (2381, 3,3133,    44, 44); 
INSERT INTO A_order_items VALUES (2382, 3,3114,   100, 65); 
INSERT INTO A_order_items VALUES (2389, 3,3123,    80, 21); 
INSERT INTO A_order_items VALUES (2391, 3,1797,   348,  7); 
INSERT INTO A_order_items VALUES (2392, 3,3117,    38, 58); 
INSERT INTO A_order_items VALUES (2393, 3,3064,  1017,  5); 
INSERT INTO A_order_items VALUES (2394, 3,3124,    82, 39); 
INSERT INTO A_order_items VALUES (2396, 3,3110,    44, 79); 
INSERT INTO A_order_items VALUES (2399, 3,2299,    76, 15); 
INSERT INTO A_order_items VALUES (2400, 3,2986,   123,  4); 
INSERT INTO A_order_items VALUES (2410, 2,2982,    40,  5);
INSERT INTO A_order_items VALUES (2411, 3,3097,   2.2,  6); 
INSERT INTO A_order_items VALUES (2412, 3,3123,  71.5, 68); 
INSERT INTO A_order_items VALUES (2413, 3,3117,    35, 44); 
INSERT INTO A_order_items VALUES (2414, 3,3220,    41,  9);
INSERT INTO A_order_items VALUES (2418, 3,3097,   2.2, 13); 
INSERT INTO A_order_items VALUES (2419, 3,3123,  71.5, 48); 
INSERT INTO A_order_items VALUES (2420, 3,3114,   101, 15); 
INSERT INTO A_order_items VALUES (2421, 3,3112,    72,164); 
INSERT INTO A_order_items VALUES (2422, 3,3123,  71.5,  5); 
INSERT INTO A_order_items VALUES (2424, 3,3359,   111, 12); 
INSERT INTO A_order_items VALUES (2425, 3,3515,   1.1,  4); 
INSERT INTO A_order_items VALUES (2428, 3,3114,   101,  5); 
INSERT INTO A_order_items VALUES (2429, 3,3110,    45, 43); 
INSERT INTO A_order_items VALUES (2430, 3,3359,   111, 10); 
INSERT INTO A_order_items VALUES (2431, 3,3114,   101,  3); 
INSERT INTO A_order_items VALUES (2436, 3,3216,    30,  3);
INSERT INTO A_order_items VALUES (2439, 3,1820,    54,  9);
INSERT INTO A_order_items VALUES (2440, 3,2302,   150,  2); 
INSERT INTO A_order_items VALUES (2442, 3,2418,    60, 23); 
INSERT INTO A_order_items VALUES (2444, 3,3133,    43, 90); 
INSERT INTO A_order_items VALUES (2450, 3,3197,    44,  5);
INSERT INTO A_order_items VALUES (2454, 3,2299,    71,  3);
INSERT INTO A_order_items VALUES (2457, 3,3127, 488.4, 17); 
INSERT INTO A_order_items VALUES (2458, 3,3127, 488.4,114); 
INSERT INTO A_order_items VALUES (2354, 4,3129,    41, 47); 
INSERT INTO A_order_items VALUES (2361, 4,2311,  86.9,185); 
INSERT INTO A_order_items VALUES (2362, 4,2316,    22,168); 
INSERT INTO A_order_items VALUES (2365, 4,2308,    56, 29); 
INSERT INTO A_order_items VALUES (2366, 4,2373,     6,  7); 
INSERT INTO A_order_items VALUES (2367, 4,2302,   147, 32); 
INSERT INTO A_order_items VALUES (2369, 4,3165,    34, 10); 
INSERT INTO A_order_items VALUES (2371, 4,2293,    96,  8);
INSERT INTO A_order_items VALUES (2375, 4,3127, 488.4, 86); 
INSERT INTO A_order_items VALUES (2377, 4,2302,   147,119); 
INSERT INTO A_order_items VALUES (2378, 4,2417,    27, 11); 
INSERT INTO A_order_items VALUES (2379, 4,3114,    98, 14); 
INSERT INTO A_order_items VALUES (2380, 4,3127, 488.4, 24); 
INSERT INTO A_order_items VALUES (2381, 4,3139,    20, 45); 
INSERT INTO A_order_items VALUES (2382, 4,3117,    35, 66); 
INSERT INTO A_order_items VALUES (2383, 4,2418,    56, 45); 
INSERT INTO A_order_items VALUES (2386, 3,2340,    71, 14); 
INSERT INTO A_order_items VALUES (2389, 4,3129,    46, 22); 
INSERT INTO A_order_items VALUES (2391, 4,1799, 961.4, 10); 
INSERT INTO A_order_items VALUES (2393, 4,3069,   385,  8); 
INSERT INTO A_order_items VALUES (2394, 4,3129,    46, 41); 
INSERT INTO A_order_items VALUES (2396, 4,3114,   100, 83); 
INSERT INTO A_order_items VALUES (2397, 4,2986,   120,  8); 
INSERT INTO A_order_items VALUES (2399, 4,2302,   149, 17); 
INSERT INTO A_order_items VALUES (2410, 3,2986,   120,  6); 
INSERT INTO A_order_items VALUES (2411, 4,3099,   3.3,  7); 
INSERT INTO A_order_items VALUES (2412, 4,3127,   492, 72); 
INSERT INTO A_order_items VALUES (2413, 4,3127,   492, 44); 
INSERT INTO A_order_items VALUES (2414, 4,3234,    39, 11); 
INSERT INTO A_order_items VALUES (2420, 4,3123,    79, 20); 
INSERT INTO A_order_items VALUES (2421, 4,3117,    41,165); 
INSERT INTO A_order_items VALUES (2426, 4,3216,    30, 11); 
INSERT INTO A_order_items VALUES (2428, 4,3117,    41,  6);
INSERT INTO A_order_items VALUES (2429, 4,3123,    79, 46); 
INSERT INTO A_order_items VALUES (2430, 4,3362,    94, 10); 
INSERT INTO A_order_items VALUES (2431, 4,3117,    41,  7);
INSERT INTO A_order_items VALUES (2432, 3,2986,   122,  5); 
INSERT INTO A_order_items VALUES (2436, 4,3224,    32,  6);
INSERT INTO A_order_items VALUES (2439, 4,1822,1433.3, 13); 
INSERT INTO A_order_items VALUES (2442, 4,2422,   144, 25); 
INSERT INTO A_order_items VALUES (2443, 3,3124,    82,  6);
INSERT INTO A_order_items VALUES (2444, 4,3139,    21, 93); 
INSERT INTO A_order_items VALUES (2447, 3,2272,   121, 24); 
INSERT INTO A_order_items VALUES (2458, 4,3134,    17,115); 
INSERT INTO A_order_items VALUES (2354, 5,3139,    21, 48); 
INSERT INTO A_order_items VALUES (2355, 4,2308,    57,185); 
INSERT INTO A_order_items VALUES (2356, 5,2293,    98, 40); 
INSERT INTO A_order_items VALUES (2358, 5,1797, 316.8, 12); 
INSERT INTO A_order_items VALUES (2359, 5,2359,   249,  1); 
INSERT INTO A_order_items VALUES (2361, 5,2316,    22,187); 
INSERT INTO A_order_items VALUES (2365, 5,2311,    95, 29); 
INSERT INTO A_order_items VALUES (2366, 5,2382, 804.1, 10); 
INSERT INTO A_order_items VALUES (2368, 4,3123,    81, 70); 
INSERT INTO A_order_items VALUES (2372, 4,3123,    81, 10); 
INSERT INTO A_order_items VALUES (2374, 5,2449,    78, 15); 
INSERT INTO A_order_items VALUES (2375, 5,3133,    45, 88); 
INSERT INTO A_order_items VALUES (2376, 5,2293,    99, 13); 
INSERT INTO A_order_items VALUES (2377, 5,2311,    95,121); 
INSERT INTO A_order_items VALUES (2378, 5,2423,    79, 11); 
INSERT INTO A_order_items VALUES (2380, 5,3133,    46, 28); 
INSERT INTO A_order_items VALUES (2381, 5,3143,    15, 48); 
INSERT INTO A_order_items VALUES (2382, 5,3123,    79, 71); 
INSERT INTO A_order_items VALUES (2383, 5,2422,   146, 46); 
INSERT INTO A_order_items VALUES (2385, 5,2302, 133.1, 87); 
INSERT INTO A_order_items VALUES (2388, 5,2308,    56, 96); 
INSERT INTO A_order_items VALUES (2391, 5,1808,    55, 15); 
INSERT INTO A_order_items VALUES (2393, 5,3077, 260.7,  8); 
INSERT INTO A_order_items VALUES (2394, 5,3133,    46, 45); 
INSERT INTO A_order_items VALUES (2399, 5,2308,    56, 17); 
INSERT INTO A_order_items VALUES (2408, 5,2783,    10, 10); 
INSERT INTO A_order_items VALUES (2410, 4,2995,    68,  8);
INSERT INTO A_order_items VALUES (2411, 5,3101,    73,  8);
INSERT INTO A_order_items VALUES (2412, 5,3134,    18, 75); 
INSERT INTO A_order_items VALUES (2413, 5,3129,    46, 45); 
INSERT INTO A_order_items VALUES (2420, 5,3127,   496, 22); 
INSERT INTO A_order_items VALUES (2421, 5,3123,    80,168); 
INSERT INTO A_order_items VALUES (2422, 4,3127,   496,  9); 
INSERT INTO A_order_items VALUES (2427, 5,2457,   4.4,  6); 
INSERT INTO A_order_items VALUES (2428, 5,3123,    80,  8);
INSERT INTO A_order_items VALUES (2429, 5,3127,   497, 49); 
INSERT INTO A_order_items VALUES (2431, 5,3127,   498,  9); 
INSERT INTO A_order_items VALUES (2435, 5,2311,  86.9,  8); 
INSERT INTO A_order_items VALUES (2442, 5,2430,   173, 28); 
INSERT INTO A_order_items VALUES (2444, 5,3140,    19, 95); 
INSERT INTO A_order_items VALUES (2447, 4,2278,    50, 25); 
INSERT INTO A_order_items VALUES (2354, 6,3143,    16, 53); 
INSERT INTO A_order_items VALUES (2355, 5,2311,  86.9,188); 
INSERT INTO A_order_items VALUES (2356, 6,2299,    72, 44); 
INSERT INTO A_order_items VALUES (2358, 6,1803,    55, 13); 
INSERT INTO A_order_items VALUES (2365, 6,2316,    22, 34); 
INSERT INTO A_order_items VALUES (2366, 6,2394, 116.6, 11); 
INSERT INTO A_order_items VALUES (2367, 5,2308,    54, 39); 
INSERT INTO A_order_items VALUES (2368, 5,3127,   496, 70); 
INSERT INTO A_order_items VALUES (2371, 5,2299,    73, 15); 
INSERT INTO A_order_items VALUES (2372, 5,3127,   496, 13); 
INSERT INTO A_order_items VALUES (2375, 6,3134,    17, 90); 
INSERT INTO A_order_items VALUES (2376, 6,2299,    73, 17); 
INSERT INTO A_order_items VALUES (2378, 6,2424, 217.8, 15); 
INSERT INTO A_order_items VALUES (2380, 6,3140,    20, 30); 
INSERT INTO A_order_items VALUES (2382, 6,3127,   496, 71); 
INSERT INTO A_order_items VALUES (2383, 6,2430,   174, 50); 
INSERT INTO A_order_items VALUES (2384, 5,2316,    21, 58); 
INSERT INTO A_order_items VALUES (2391, 6,1820,    52, 18); 
INSERT INTO A_order_items VALUES (2392, 6,3124,    77, 63); 
INSERT INTO A_order_items VALUES (2393, 6,3082,    78, 10); 
INSERT INTO A_order_items VALUES (2394, 6,3134,    18, 45); 
INSERT INTO A_order_items VALUES (2399, 6,2311,  86.9, 20); 
INSERT INTO A_order_items VALUES (2400, 6,2999,   880, 16); 
INSERT INTO A_order_items VALUES (2411, 6,3106,    45, 11); 
INSERT INTO A_order_items VALUES (2412, 6,3139,    20, 79); 
INSERT INTO A_order_items VALUES (2418, 6,3110,    45, 20); 
INSERT INTO A_order_items VALUES (2419, 4,3129,    43, 57); 
INSERT INTO A_order_items VALUES (2421, 6,3129,    43,172); 
INSERT INTO A_order_items VALUES (2422, 5,3133,    46, 11); 
INSERT INTO A_order_items VALUES (2423, 5,3245, 214.5, 13); 
INSERT INTO A_order_items VALUES (2427, 6,2464,    66,  6);
INSERT INTO A_order_items VALUES (2428, 6,3127,   498, 12); 
INSERT INTO A_order_items VALUES (2429, 6,3133,    46, 52); 
INSERT INTO A_order_items VALUES (2431, 6,3129,    44, 11); 
INSERT INTO A_order_items VALUES (2434, 6,2236, 949.3, 84); 
INSERT INTO A_order_items VALUES (2435, 6,2316,    21, 10); 
INSERT INTO A_order_items VALUES (2440, 6,2311,  86.9,  7); 
INSERT INTO A_order_items VALUES (2442, 6,2439, 115.5, 30); 
INSERT INTO A_order_items VALUES (2444, 6,3143,    15, 97); 
INSERT INTO A_order_items VALUES (2445, 5,2293,    97, 11); 
INSERT INTO A_order_items VALUES (2448, 5,3133,    42, 11); 
INSERT INTO A_order_items VALUES (2452, 6,3139,    20, 10); 
INSERT INTO A_order_items VALUES (2354, 7,3150,    17, 58); 
INSERT INTO A_order_items VALUES (2355, 6,2322,    19,188); 
INSERT INTO A_order_items VALUES (2356, 7,2308,    58, 47); 
INSERT INTO A_order_items VALUES (2357, 7,2245,   462, 26); 
INSERT INTO A_order_items VALUES (2358, 7,1808,    55, 14); 
INSERT INTO A_order_items VALUES (2362, 7,2326,   1.1,173); 
INSERT INTO A_order_items VALUES (2363, 7,2299,    74, 25); 
INSERT INTO A_order_items VALUES (2365, 7,2319,    24, 38); 
INSERT INTO A_order_items VALUES (2366, 7,2395,   120, 12); 
INSERT INTO A_order_items VALUES (2368, 6,3129,    42, 72); 
INSERT INTO A_order_items VALUES (2372, 6,3134,    17, 17); 
INSERT INTO A_order_items VALUES (2375, 7,3143,    15, 93); 
INSERT INTO A_order_items VALUES (2376, 7,2302, 133.1, 21); 
INSERT INTO A_order_items VALUES (2379, 7,3127, 488.4, 23); 
INSERT INTO A_order_items VALUES (2380, 7,3143,    15, 31); 
INSERT INTO A_order_items VALUES (2382, 7,3129,    42, 76); 
INSERT INTO A_order_items VALUES (2383, 7,2439, 115.5, 54); 
INSERT INTO A_order_items VALUES (2384, 6,2322,    22, 59); 
INSERT INTO A_order_items VALUES (2387, 7,2243, 332.2, 20); 
INSERT INTO A_order_items VALUES (2391, 7,1822,1433.3, 23); 
INSERT INTO A_order_items VALUES (2392, 7,3133,    45, 66); 
INSERT INTO A_order_items VALUES (2393, 7,3086,   211, 13); 
INSERT INTO A_order_items VALUES (2394, 7,3140,    19, 48); 
INSERT INTO A_order_items VALUES (2395, 7,2243, 332.2, 27); 
INSERT INTO A_order_items VALUES (2397, 7,2999,   880, 16); 
INSERT INTO A_order_items VALUES (2399, 7,2316,    22, 24); 
INSERT INTO A_order_items VALUES (2400, 7,3003,2866.6, 19); 
INSERT INTO A_order_items VALUES (2412, 7,3143,    16, 80); 
INSERT INTO A_order_items VALUES (2414, 7,3246, 212.3, 18); 
INSERT INTO A_order_items VALUES (2419, 5,3133,    45, 61); 
INSERT INTO A_order_items VALUES (2420, 6,3133,    48, 29); 
INSERT INTO A_order_items VALUES (2423, 6,3246, 212.3, 14); 
INSERT INTO A_order_items VALUES (2427, 7,2470,    76,  6);
INSERT INTO A_order_items VALUES (2428, 7,3133,    48, 12); 
INSERT INTO A_order_items VALUES (2429, 7,3139,    21, 54); 
INSERT INTO A_order_items VALUES (2432, 6,2999,   880, 11); 
INSERT INTO A_order_items VALUES (2434, 7,2245,   462, 86); 
INSERT INTO A_order_items VALUES (2435, 7,2323,    18, 12); 
INSERT INTO A_order_items VALUES (2436, 7,3245, 214.5, 16); 
INSERT INTO A_order_items VALUES (2437, 7,2457,   4.4, 17); 
INSERT INTO A_order_items VALUES (2440, 7,2322,    23, 10); 
INSERT INTO A_order_items VALUES (2443, 6,3139,    20, 12); 
INSERT INTO A_order_items VALUES (2444, 7,3150,    17,100); 
INSERT INTO A_order_items VALUES (2445, 6,2299,    72, 14); 
INSERT INTO A_order_items VALUES (2448, 6,3134,    17, 14); 
INSERT INTO A_order_items VALUES (2450, 6,3216,    29, 11); 
INSERT INTO A_order_items VALUES (2452, 7,3143,    15, 12); 
INSERT INTO A_order_items VALUES (2454, 6,2308,    55, 12); 
INSERT INTO A_order_items VALUES (2455, 6,2496, 268.4, 32); 
INSERT INTO A_order_items VALUES (2456, 7,2537, 193.6, 19); 
INSERT INTO A_order_items VALUES (2354, 8,3163,    30, 61); 
INSERT INTO A_order_items VALUES (2355, 7,2323,    17,190); 
INSERT INTO A_order_items VALUES (2356, 8,2311,    95, 51); 
INSERT INTO A_order_items VALUES (2357, 8,2252, 788.7, 26); 
INSERT INTO A_order_items VALUES (2361, 8,2326,   1.1,194); 
INSERT INTO A_order_items VALUES (2362, 8,2334,   3.3,177); 
INSERT INTO A_order_items VALUES (2363, 8,2308,    57, 26); 
INSERT INTO A_order_items VALUES (2365, 8,2322,    19, 43); 
INSERT INTO A_order_items VALUES (2366, 8,2400,   418, 16); 
INSERT INTO A_order_items VALUES (2369, 7,3170, 145.2, 24); 
INSERT INTO A_order_items VALUES (2372, 7,3143,    15, 21); 
INSERT INTO A_order_items VALUES (2374, 8,2467,    79, 21); 
INSERT INTO A_order_items VALUES (2375, 8,3150,    17, 93); 
INSERT INTO A_order_items VALUES (2376, 8,2311,    95, 25); 
INSERT INTO A_order_items VALUES (2380, 8,3150,    17, 33); 
INSERT INTO A_order_items VALUES (2382, 8,3139,    21, 79); 
INSERT INTO A_order_items VALUES (2384, 7,2330,   1.1, 61); 
INSERT INTO A_order_items VALUES (2385, 8,2311,  86.9, 96); 
INSERT INTO A_order_items VALUES (2387, 8,2245,   462, 22); 
INSERT INTO A_order_items VALUES (2389, 7,3143,    15, 30); 
INSERT INTO A_order_items VALUES (2390, 8,1948, 470.8, 16); 
INSERT INTO A_order_items VALUES (2392, 8,3139,    21, 68); 
INSERT INTO A_order_items VALUES (2393, 8,3087, 108.9, 14); 
INSERT INTO A_order_items VALUES (2395, 8,2252, 788.7, 30); 
INSERT INTO A_order_items VALUES (2397, 8,3000,1696.2, 16); 
INSERT INTO A_order_items VALUES (2399, 8,2326,   1.1, 27); 
INSERT INTO A_order_items VALUES (2407, 8,2752,    86, 18); 
INSERT INTO A_order_items VALUES (2411, 7,3112,    72, 17); 
INSERT INTO A_order_items VALUES (2414, 8,3253, 206.8, 23); 
INSERT INTO A_order_items VALUES (2420, 7,3140,    19, 34); 
INSERT INTO A_order_items VALUES (2423, 7,3251,    26, 16); 
INSERT INTO A_order_items VALUES (2426, 8,3234,    34, 18); 
INSERT INTO A_order_items VALUES (2428, 8,3143,    16, 13); 
INSERT INTO A_order_items VALUES (2434, 8,2252, 788.7, 87); 
INSERT INTO A_order_items VALUES (2435, 8,2334,   3.3, 14); 
INSERT INTO A_order_items VALUES (2436, 8,3250,    27, 18); 
INSERT INTO A_order_items VALUES (2437, 8,2462,    76, 19); 
INSERT INTO A_order_items VALUES (2440, 8,2330,   1.1, 13); 
INSERT INTO A_order_items VALUES (2443, 7,3143,    15, 17); 
INSERT INTO A_order_items VALUES (2444, 8,3155,    43,104); 
INSERT INTO A_order_items VALUES (2448, 7,3139,    20, 15); 
INSERT INTO A_order_items VALUES (2450, 7,3220,    41, 14); 
INSERT INTO A_order_items VALUES (2451, 7,1948, 470.8, 22); 
INSERT INTO A_order_items VALUES (2452, 8,3150,    17, 13); 
INSERT INTO A_order_items VALUES (2454, 7,2316,    21, 13); 
INSERT INTO A_order_items VALUES (2457, 8,3150,    17, 27); 
INSERT INTO A_order_items VALUES (2458, 7,3143,    15,129); 
INSERT INTO A_order_items VALUES (2354, 9,3165,    37, 64); 
INSERT INTO A_order_items VALUES (2355, 8,2326,   1.1,192); 
INSERT INTO A_order_items VALUES (2356, 9,2316,    22, 55); 
INSERT INTO A_order_items VALUES (2357, 9,2257, 371.8, 29); 
INSERT INTO A_order_items VALUES (2360, 8,2093,   7.7, 42); 
INSERT INTO A_order_items VALUES (2361, 9,2334,   3.3,198); 
INSERT INTO A_order_items VALUES (2362, 9,2339,    25,179); 
INSERT INTO A_order_items VALUES (2363, 9,2311,  86.9, 29); 
INSERT INTO A_order_items VALUES (2364, 8,1948, 470.8, 20); 
INSERT INTO A_order_items VALUES (2365, 9,2326,   1.1, 44); 
INSERT INTO A_order_items VALUES (2366, 9,2406, 195.8, 20); 
INSERT INTO A_order_items VALUES (2367, 8,2322,    22, 45); 
INSERT INTO A_order_items VALUES (2369, 8,3176, 113.3, 24); 
INSERT INTO A_order_items VALUES (2371, 8,2316,    21, 21); 
INSERT INTO A_order_items VALUES (2375, 9,3155,    45, 98); 
INSERT INTO A_order_items VALUES (2376, 9,2316,    21, 27); 
INSERT INTO A_order_items VALUES (2377, 8,2319,    25,131); 
INSERT INTO A_order_items VALUES (2380, 9,3155,    45, 33); 
INSERT INTO A_order_items VALUES (2381, 8,3163,    35, 55); 
INSERT INTO A_order_items VALUES (2382, 9,3143,    15, 82); 
INSERT INTO A_order_items VALUES (2385, 9,2319,    25, 97); 
INSERT INTO A_order_items VALUES (2386, 8,2365,    77, 27); 
INSERT INTO A_order_items VALUES (2387, 9,2252, 788.7, 27); 
INSERT INTO A_order_items VALUES (2389, 8,3155,    46, 33); 
INSERT INTO A_order_items VALUES (2392, 9,3150,    18, 72); 
INSERT INTO A_order_items VALUES (2393, 9,3091,   278, 19); 
INSERT INTO A_order_items VALUES (2396, 9,3140,    19, 93); 
INSERT INTO A_order_items VALUES (2399, 9,2330,   1.1, 28); 
INSERT INTO A_order_items VALUES (2406, 8,2761,    26, 19); 
INSERT INTO A_order_items VALUES (2407, 9,2761,    26, 21); 
INSERT INTO A_order_items VALUES (2410, 7,3003,2866.6, 15); 
INSERT INTO A_order_items VALUES (2411, 8,3123,    75, 17); 
INSERT INTO A_order_items VALUES (2414, 9,3260,    50, 24); 
INSERT INTO A_order_items VALUES (2420, 8,3143,    15, 39); 
INSERT INTO A_order_items VALUES (2422, 8,3150,    17, 25); 
INSERT INTO A_order_items VALUES (2423, 8,3258,    78, 21); 
INSERT INTO A_order_items VALUES (2428, 9,3150,    17, 16); 
INSERT INTO A_order_items VALUES (2429, 8,3150,    17, 55); 
INSERT INTO A_order_items VALUES (2434, 9,2254, 408.1, 92); 
INSERT INTO A_order_items VALUES (2435, 9,2339,    25, 19); 
INSERT INTO A_order_items VALUES (2436, 9,3256,    36, 18); 
INSERT INTO A_order_items VALUES (2437, 9,2464,    64, 21); 
INSERT INTO A_order_items VALUES (2440, 9,2334,   3.3, 15); 
INSERT INTO A_order_items VALUES (2442, 9,2459, 624.8, 40); 
INSERT INTO A_order_items VALUES (2443, 8,3150,    18, 17); 
INSERT INTO A_order_items VALUES (2447, 8,2293,    97, 34); 
INSERT INTO A_order_items VALUES (2448, 8,3143,    16, 16); 
INSERT INTO A_order_items VALUES (2450, 8,3224,    32, 16); 
INSERT INTO A_order_items VALUES (2452, 9,3155,    44, 13); 
INSERT INTO A_order_items VALUES (2454, 8,2323,    18, 16); 
INSERT INTO A_order_items VALUES (2457, 9,3155,    44, 32); 
INSERT INTO A_order_items VALUES (2354,10,3167,    51, 68); 
INSERT INTO A_order_items VALUES (2355, 9,2330,   1.1,197); 
INSERT INTO A_order_items VALUES (2356,10,2323,    18, 55); 
INSERT INTO A_order_items VALUES (2357,10,2262,    95, 29); 
INSERT INTO A_order_items VALUES (2359, 8,2370,    91, 17); 
INSERT INTO A_order_items VALUES (2363,10,2319,    24, 31); 
INSERT INTO A_order_items VALUES (2365,10,2335,    97, 45); 
INSERT INTO A_order_items VALUES (2366,10,2409, 194.7, 22); 
INSERT INTO A_order_items VALUES (2367, 9,2326,   1.1, 48); 
INSERT INTO A_order_items VALUES (2368, 9,3143,    16, 75); 
INSERT INTO A_order_items VALUES (2369, 9,3187,   2.2, 24); 
INSERT INTO A_order_items VALUES (2371, 9,2323,    17, 24); 
INSERT INTO A_order_items VALUES (2375,10,3163,    30, 99); 
INSERT INTO A_order_items VALUES (2376,10,2319,    25, 32); 
INSERT INTO A_order_items VALUES (2377, 9,2326,   1.1,132); 
INSERT INTO A_order_items VALUES (2379,10,3139,    21, 34); 
INSERT INTO A_order_items VALUES (2380,10,3163,    32, 36); 
INSERT INTO A_order_items VALUES (2383,10,2457,   4.4, 62); 
INSERT INTO A_order_items VALUES (2386, 9,2370,    90, 28); 
INSERT INTO A_order_items VALUES (2387,10,2253, 354.2, 32); 
INSERT INTO A_order_items VALUES (2388,10,2330,   1.1,105); 
INSERT INTO A_order_items VALUES (2392,10,3155,    49, 77); 
INSERT INTO A_order_items VALUES (2393,10,3099,   3.3, 19); 
INSERT INTO A_order_items VALUES (2394,10,3155,    49, 61); 
INSERT INTO A_order_items VALUES (2395, 9,2255, 690.8, 34); 
INSERT INTO A_order_items VALUES (2396,10,3150,    17, 93); 
INSERT INTO A_order_items VALUES (2399,10,2335,   100, 33); 
INSERT INTO A_order_items VALUES (2411, 9,3124,    84, 17); 
INSERT INTO A_order_items VALUES (2419, 8,3150,    17, 69); 
INSERT INTO A_order_items VALUES (2421, 9,3143,    15,176); 
INSERT INTO A_order_items VALUES (2422, 9,3155,    43, 29); 
INSERT INTO A_order_items VALUES (2434,10,2257, 371.8, 94); 
INSERT INTO A_order_items VALUES (2435,10,2350,2341.9, 24); 
INSERT INTO A_order_items VALUES (2440,10,2337, 270.6, 19); 
INSERT INTO A_order_items VALUES (2442,10,2467,    80, 44); 
INSERT INTO A_order_items VALUES (2443, 9,3155,    43, 21); 
INSERT INTO A_order_items VALUES (2445, 9,2311,    95, 24); 
INSERT INTO A_order_items VALUES (2446, 9,2326,   1.1, 34); 
INSERT INTO A_order_items VALUES (2447, 9,2299,    76, 35); 
INSERT INTO A_order_items VALUES (2452,10,3165,    34, 18); 
INSERT INTO A_order_items VALUES (2454, 9,2334,   3.3, 18); 
INSERT INTO A_order_items VALUES (2354,11,3170, 145.2, 70); 
INSERT INTO A_order_items VALUES (2355,10,2339,    25,199); 
INSERT INTO A_order_items VALUES (2357,11,2268,    75, 32); 
INSERT INTO A_order_items VALUES (2359, 9,2373,     6, 17);
INSERT INTO A_order_items VALUES (2363,11,2323,    18, 34); 
INSERT INTO A_order_items VALUES (2365,11,2339,    25, 50); 
INSERT INTO A_order_items VALUES (2366,11,2415, 339.9, 24); 
INSERT INTO A_order_items VALUES (2367,10,2330,   1.1, 52); 
INSERT INTO A_order_items VALUES (2368,10,3155,    45, 75); 
INSERT INTO A_order_items VALUES (2369,10,3193,   2.2, 28); 
INSERT INTO A_order_items VALUES (2371,10,2334,   3.3, 26); 
INSERT INTO A_order_items VALUES (2372,10,3163,    30, 30); 
INSERT INTO A_order_items VALUES (2375,11,3165,    36,103); 
INSERT INTO A_order_items VALUES (2376,11,2326,   1.1, 33); 
INSERT INTO A_order_items VALUES (2377,10,2330,   1.1,136); 
INSERT INTO A_order_items VALUES (2379,11,3140,    19, 35); 
INSERT INTO A_order_items VALUES (2380,11,3167,    52, 37); 
INSERT INTO A_order_items VALUES (2383,11,2462,    75, 63); 
INSERT INTO A_order_items VALUES (2386,10,2375,    73, 32); 
INSERT INTO A_order_items VALUES (2395,10,2264, 199.1, 34); 
INSERT INTO A_order_items VALUES (2396,11,3155,    47, 98); 
INSERT INTO A_order_items VALUES (2398,11,2537, 193.6, 23); 
INSERT INTO A_order_items VALUES (2411,10,3127, 488.4, 18); 
INSERT INTO A_order_items VALUES (2413,11,3155,    47, 62); 
INSERT INTO A_order_items VALUES (2418,11,3140,    20, 31); 
INSERT INTO A_order_items VALUES (2419, 9,3155,    47, 72); 
INSERT INTO A_order_items VALUES (2421,10,3150,    17,176); 
INSERT INTO A_order_items VALUES (2440,11,2339,    25, 23); 
INSERT INTO A_order_items VALUES (2444,11,3165,    37,112); 
INSERT INTO A_order_items VALUES (2445,10,2319,    25, 27); 
INSERT INTO A_order_items VALUES (2446,10,2330,   1.1, 36); 
INSERT INTO A_order_items VALUES (2447,10,2302, 133.1, 37); 
INSERT INTO A_order_items VALUES (2452,11,3170, 145.2, 20); 
INSERT INTO A_order_items VALUES (2354,12,3176, 113.3, 72); 
INSERT INTO A_order_items VALUES (2359,10,2377,    96, 17); 
INSERT INTO A_order_items VALUES (2363,12,2326,   1.1, 37); 
INSERT INTO A_order_items VALUES (2365,12,2340,    72, 54); 
INSERT INTO A_order_items VALUES (2366,12,2419,    69, 24); 
INSERT INTO A_order_items VALUES (2367,11,2335,  91.3, 54); 
INSERT INTO A_order_items VALUES (2371,11,2339,    25, 29); 
INSERT INTO A_order_items VALUES (2372,11,3167,    54, 32); 
INSERT INTO A_order_items VALUES (2375,12,3171,   132,107); 
INSERT INTO A_order_items VALUES (2376,12,2334,   3.3, 36); 
INSERT INTO A_order_items VALUES (2378,12,2457,   4.4, 25); 
INSERT INTO A_order_items VALUES (2380,12,3176, 113.3, 40); 
INSERT INTO A_order_items VALUES (2381,11,3176, 113.3, 62); 
INSERT INTO A_order_items VALUES (2382,12,3163,    29, 89); 
INSERT INTO A_order_items VALUES (2385,12,2335,  91.3,106); 
INSERT INTO A_order_items VALUES (2386,11,2378, 271.7, 33); 
INSERT INTO A_order_items VALUES (2389,11,3165,    34, 43); 
INSERT INTO A_order_items VALUES (2395,11,2268,    71, 37); 
INSERT INTO A_order_items VALUES (2396,12,3163,    29,100); 
INSERT INTO A_order_items VALUES (2398,12,2594,     9, 27); 
INSERT INTO A_order_items VALUES (2410,10,3051,    12, 21); 
INSERT INTO A_order_items VALUES (2411,11,3133,    43, 23); 
INSERT INTO A_order_items VALUES (2412,12,3163,    30, 92); 
INSERT INTO A_order_items VALUES (2413,12,3163,    30, 66); 
INSERT INTO A_order_items VALUES (2419,10,3165,    35, 76); 
INSERT INTO A_order_items VALUES (2420,11,3163,    30, 45); 
INSERT INTO A_order_items VALUES (2422,10,3163,    30, 35); 
INSERT INTO A_order_items VALUES (2426,12,3248, 212.3, 26); 
INSERT INTO A_order_items VALUES (2427,12,2496, 268.4, 19); 
INSERT INTO A_order_items VALUES (2428,12,3170, 145.2, 24); 
INSERT INTO A_order_items VALUES (2429,11,3163,    30, 63); 
INSERT INTO A_order_items VALUES (2440,12,2350,2341.9, 24); 
INSERT INTO A_order_items VALUES (2444,12,3172,    37,112); 
INSERT INTO A_order_items VALUES (2445,11,2326,   1.1, 28); 
INSERT INTO A_order_items VALUES (2446,11,2337, 270.6, 37); 
INSERT INTO A_order_items VALUES (2447,11,2308,    54, 40); 
INSERT INTO A_order_items VALUES (2452,12,3172,    37, 20); 
INSERT INTO A_order_items VALUES (2457,12,3170, 145.2, 42); 
INSERT INTO A_order_items VALUES (2354,13,3182,    61, 77); 
INSERT INTO A_order_items VALUES (2357,12,2276, 236.5, 38); 
INSERT INTO A_order_items VALUES (2359,11,2380,   5.5, 17); 
INSERT INTO A_order_items VALUES (2361,12,2359,   248,208); 
INSERT INTO A_order_items VALUES (2362,12,2359,   248,189); 
INSERT INTO A_order_items VALUES (2363,13,2334,   3.3, 42); 
INSERT INTO A_order_items VALUES (2367,12,2350,2341.9, 54); 
INSERT INTO A_order_items VALUES (2369,11,3204,   123, 34); 
INSERT INTO A_order_items VALUES (2371,12,2350,2341.9, 32); 
INSERT INTO A_order_items VALUES (2372,12,3170, 145.2, 36); 
INSERT INTO A_order_items VALUES (2375,13,3176,   120,109); 
INSERT INTO A_order_items VALUES (2378,13,2459, 624.8, 25); 
INSERT INTO A_order_items VALUES (2380,13,3187,   2.2, 40); 
INSERT INTO A_order_items VALUES (2381,12,3183,    47, 63); 
INSERT INTO A_order_items VALUES (2382,13,3165,    37, 92); 
INSERT INTO A_order_items VALUES (2384,12,2359,   249, 77); 
INSERT INTO A_order_items VALUES (2385,13,2350,2341.9,109); 
INSERT INTO A_order_items VALUES (2386,12,2394, 116.6, 36); 
INSERT INTO A_order_items VALUES (2387,13,2268,    75, 42); 
INSERT INTO A_order_items VALUES (2388,13,2350,2341.9,112); 
INSERT INTO A_order_items VALUES (2389,12,3167,    52, 47); 
INSERT INTO A_order_items VALUES (2392,13,3165,    40, 81); 
INSERT INTO A_order_items VALUES (2393,13,3108,  69.3, 30); 
INSERT INTO A_order_items VALUES (2394,13,3167,    52, 68); 
INSERT INTO A_order_items VALUES (2395,12,2270,    64, 41); 
INSERT INTO A_order_items VALUES (2399,13,2359, 226.6, 38); 
INSERT INTO A_order_items VALUES (2404,13,2808,     0, 37); 
INSERT INTO A_order_items VALUES (2406,12,2782,    62, 31); 
INSERT INTO A_order_items VALUES (2411,12,3143,    15, 24); 
INSERT INTO A_order_items VALUES (2412,13,3167,    54, 94); 
INSERT INTO A_order_items VALUES (2417,13,2976,    51, 37); 
INSERT INTO A_order_items VALUES (2418,12,3150,    17, 37); 
INSERT INTO A_order_items VALUES (2419,11,3167,    54, 81); 
INSERT INTO A_order_items VALUES (2420,12,3171,   132, 47); 
INSERT INTO A_order_items VALUES (2421,11,3155,    43,185); 
INSERT INTO A_order_items VALUES (2422,11,3167,    54, 39); 
INSERT INTO A_order_items VALUES (2423,12,3290,    65, 33); 
INSERT INTO A_order_items VALUES (2426,13,3252,    25, 29); 
INSERT INTO A_order_items VALUES (2427,13,2522,    40, 22); 
INSERT INTO A_order_items VALUES (2428,13,3173,    86, 28); 
INSERT INTO A_order_items VALUES (2429,12,3165,    36, 67); 
INSERT INTO A_order_items VALUES (2430,13,3501, 492.8, 43); 
INSERT INTO A_order_items VALUES (2434,13,2268,    75,104); 
INSERT INTO A_order_items VALUES (2435,13,2365,    75, 33); 
INSERT INTO A_order_items VALUES (2436,13,3290,    63, 24); 
INSERT INTO A_order_items VALUES (2437,13,2496, 268.4, 35); 
INSERT INTO A_order_items VALU ES (2440,13,2359, 226.6, 28); 
INSERT INTO A_order_items VALUES (2443,12,3165,    36, 31); 
INSERT INTO A_order_items VALUES (2444,13,3182,    63,115); 
INSERT INTO A_order_items VALUES (2446,12,2350,2341.9, 39); 
INSERT INTO A_order_items VALUES (2447,12,2311,    93, 44); 
INSERT INTO A_order_items VALUES (2452,13,3173,    80, 23); 
INSERT INTO A_order_items VALUES (2455,12,2536,    75, 54); 
INSERT INTO A_order_items VALUES (2457,13,3172,    36, 45); 
INSERT INTO A_order_items VALUES (2458,12,3163,    32,142); 
INSERT INTO A_order_items VALUES (2355,13,2359, 226.6,204); 
INSERT INTO A_order_items VALUES (2357,13,2289,    48, 41); 
INSERT INTO A_order_items VALUES (2359,12,2381,    97, 17); 
INSERT INTO A_order_items VALUES (2361,13,2365,    76,209); 
COMMIT;

