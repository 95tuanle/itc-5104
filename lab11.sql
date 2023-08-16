SELECT COUNT(*)
FROM BOOKS
WHERE CATEGORY = 'COOKING';



SELECT COUNT(*)
FROM BOOKS
WHERE RETAIL > 30.00;



SELECT MAX(PUBDATE)
FROM BOOKS;



SELECT SUM(OI.QUANTITY * (OI.PAIDEACH - B.COST))
FROM ORDERS O
         NATURAL JOIN ORDERITEMS OI
         NATURAL JOIN BOOKS B
WHERE O.CUSTOMER# = 1017;



SELECT MIN(RETAIL)
FROM BOOKS
WHERE CATEGORY = 'COMPUTER';



SELECT AVG(SUM(OI.QUANTITY * (OI.PAIDEACH - B.COST)))
FROM ORDERITEMS OI
         NATURAL JOIN BOOKS B
GROUP BY OI.ORDER#;



SELECT CUSTOMER#, COUNT(*)
FROM ORDERS
GROUP BY CUSTOMER#;



SELECT P.NAME, B.CATEGORY, AVG(RETAIL)
FROM BOOKS B
         NATURAL JOIN PUBLISHER P
WHERE B.CATEGORY = 'CHILDREN'
   OR B.CATEGORY = 'COMPUTER'
GROUP BY P.NAME, B.CATEGORY
HAVING AVG(RETAIL) > 50;



SELECT CUSTOMER#, SUM(OI.QUANTITY * OI.PAIDEACH)
FROM CUSTOMERS C
         NATURAL JOIN ORDERS O
         NATURAL JOIN ORDERITEMS OI
WHERE C.STATE = 'GA'
   OR C.STATE = 'FL'
GROUP BY CUSTOMER#
HAVING SUM(OI.QUANTITY * OI.PAIDEACH) > 80;



SELECT MAX(B.RETAIL)
FROM BOOKS B
         NATURAL JOIN BOOKAUTHOR BA
         NATURAL JOIN AUTHOR A
WHERE A.FNAME = 'LISA'
  AND A.LNAME = 'WHITE';



SELECT ISBN, SUM(OI.QUANTITY)
FROM BOOKS B
         LEFT OUTER JOIN ORDERITEMS OI USING (ISBN)
WHERE (B.RETAIL - B.COST) / B.COST * 100 < 55
GROUP BY ISBN;