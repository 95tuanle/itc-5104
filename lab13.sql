CREATE VIEW CONTACT
AS SELECT CONTACT, PHONE
FROM PUBLISHER;



CREATE OR REPLACE VIEW CONTACT
AS SELECT CONTACT, PHONE
FROM PUBLISHER
WITH READ ONLY;




CREATE FORCE VIEW HOMEWORK13
AS SELECT Col1, Col2
FROM FIRSTATTEMPT;



DESC HOMEWORK13;



CREATE VIEW REORDERINFO
AS SELECT ISBN, TITLE, CONTACT, PHONE
FROM BOOKS NATURAL JOIN PUBLISHER;



UPDATE REORDERINFO
SET CONTACT = 'NGUYEN ANH TUAN LE'
WHERE CONTACT = 'RENEE SMITH';



UPDATE REORDERINFO
SET ISBN = 3333333333
WHERE ISBN = 1059831198;



DELETE FROM REORDERINFO
WHERE CONTACT = 'RENEE SMITH';



ROLLBACK;



DROP VIEW REORDERINFO;



SELECT TITLE, FREQUENCY, PROFIT
FROM (SELECT B.TITLE, SUM(OI.QUANTITY) FREQUENCY, ((B.RETAIL-B.COST)/B.COST*100) PROFIT
FROM BOOKS B NATURAL JOIN ORDERITEMS OI
GROUP BY B.TITLE, ((B.RETAIL-B.COST)/B.COST*100)
ORDER BY FREQUENCY DESC)
WHERE ROWNUM <= 5;