INSERT INTO orders (order#, customer#, orderdate)
VALUES (1021, 1009, '20-JUL-09');

UPDATE orders
SET shipzip = 33222
WHERE order# = 1017;

COMMIT;

INSERT INTO orders (order#, customer#, orderdate)
VALUES (1022, 2000, '06-AUG-09');

INSERT INTO orders (order#, customer#)
VALUES (1023, 1009);

UPDATE books
SET cost = & cost
WHERE isbn = &isbn;

ROLLBACK;

ALTER TABLE orderitems
    DROP CONSTRAINT orderitems_order#_fk;

ALTER TABLE orderitems
    ADD CONSTRAINT orderitems_order#_fk FOREIGN KEY (order#)
        REFERENCES orders (order#) ON DELETE CASCADE;

DELETE
FROM orders
WHERE order# = 1005;

ROLLBACK;

drop table category purge;

CREATE TABLE category
(
    catcode VARCHAR2(3) PRIMARY KEY,
    cardesc VARCHAR2(11) NOT NULL
);

INSERT INTO category
VALUES ('BUS', 'BUSINESS');
INSERT INTO category
VALUES ('CHN', 'CHILDREN');
INSERT INTO category
VALUES ('COK', 'COOKING');
INSERT INTO category
VALUES ('COM', 'COMPUTER');
INSERT INTO category
VALUES ('FAL', 'FAMILY LIFE');
INSERT INTO category
VALUES ('FIT', 'FITNESS');
INSERT INTO category
VALUES ('SEH', 'SELF HELP');
INSERT INTO category
VALUES ('LIT', 'LITERATURE');

ALTER TABLE books
    ADD catcode VARCHAR2(3)
    ADD CONSTRAINT books_catcode_fk FOREIGN KEY (catcode)
        REFERENCES category (catcode);

UPDATE books
SET catcode = 'BUS'
WHERE CATEGORY = 'BUSINESS';
UPDATE books
SET catcode = 'CHN'
WHERE CATEGORY = 'CHILDREN';
UPDATE books
SET catcode = 'COK'
WHERE CATEGORY = 'COOKING';
UPDATE books
SET catcode = 'COM'
WHERE CATEGORY = 'COMPUTER';
UPDATE books
SET catcode = 'FAL'
WHERE CATEGORY = 'FAMILY LIFE';
UPDATE books
SET catcode = 'FIT'
WHERE CATEGORY = 'FITNESS';
UPDATE books
SET catcode = 'SEH'
WHERE CATEGORY = 'SELF HELP';
UPDATE books
SET catcode = 'LIT'
WHERE CATEGORY = 'LITERATURE';

ALTER TABLE books
    DROP COLUMN category;