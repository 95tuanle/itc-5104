SELECT EMPLOYEE_ID, FIRST_NAME, LAST_NAME
FROM EMPLOYEES
         NATURAL JOIN
         (SELECT DEPARTMENT_ID FROM DEPARTMENTS WHERE LOCATION_ID = 1700);



SELECT FIRST_NAME, LAST_NAME, SALARY, HIRE_DATE
FROM EMPLOYEES
WHERE HIRE_DATE = (SELECT MIN(HIRE_DATE) FROM EMPLOYEES);



SELECT EMPLOYEE_ID, FIRST_NAME, LAST_NAME
FROM EMPLOYEES
         NATURAL JOIN
         (SELECT DEPARTMENT_ID FROM DEPARTMENTS WHERE LOCATION_ID <> 1800)
WHERE LAST_NAME LIKE 'F%';



SELECT DEPARTMENT_ID, COUNT(*)
FROM EMPLOYEES
WHERE SALARY < (SELECT AVG(SALARY) FROM EMPLOYEES)
GROUP BY DEPARTMENT_ID;



SELECT FIRST_NAME, LAST_NAME, HIRE_DATE
FROM EMPLOYEES
         NATURAL JOIN
     (SELECT DEPARTMENT_ID
      FROM DEPARTMENTS
               NATURAL JOIN
               (SELECT LOCATION_ID FROM LOCATIONS WHERE CITY = 'London'))
WHERE HIRE_DATE BETWEEN TO_DATE('2001-01-01', 'yyyy-MM-dd') AND TO_DATE('2001-12-31', 'yyyy-MM-dd');



SELECT EMPLOYEE_ID, FIRST_NAME, LAST_NAME, SALARY, AVERAGE_SALARY, SALARY - AVERAGE_SALARY DIFFERENCE
FROM (SELECT AVG(SALARY) AVERAGE_SALARY
      FROM EMPLOYEES
               NATURAL JOIN
               (SELECT JOB_ID FROM JOBS WHERE JOB_TITLE = 'Accountant')),
     EMPLOYEES
         NATURAL JOIN (SELECT JOB_ID FROM JOBS WHERE JOB_TITLE = 'Accountant');



SELECT DEPARTMENT_ID, DEPARTMENT_NAME
FROM DEPARTMENTS
         NATURAL JOIN
     (SELECT LOCATION_ID
      FROM LOCATIONS
               NATURAL JOIN
           (SELECT COUNTRY_ID
            FROM COUNTRIES
                     NATURAL JOIN
                     (SELECT REGION_ID FROM REGIONS WHERE REGION_NAME = 'Americas')))
WHERE MANAGER_ID IS NOT NULL;



CREATE OR REPLACE VIEW manager_view
AS
SELECT E.FIRST_NAME, E.LAST_NAME, E.HIRE_DATE, M.FIRST_NAME || ' ' || M.LAST_NAME MANAGER
FROM EMPLOYEES E
         LEFT OUTER JOIN EMPLOYEES M ON E.MANAGER_ID = M.EMPLOYEE_ID
WHERE E.HIRE_DATE >= TO_DATE('2019-02-01', 'yyyy-MM-dd')
   OR M.FIRST_NAME = 'Russell'
   OR M.LAST_NAME = 'Russell';

CREATE OR REPLACE VIEW manager_view
AS
SELECT E.FIRST_NAME, E.LAST_NAME, E.HIRE_DATE, M.FIRST_NAME || ' ' || M.LAST_NAME MANAGER
FROM EMPLOYEES E,
     EMPLOYEES M
WHERE E.MANAGER_ID = M.EMPLOYEE_ID
  AND (E.HIRE_DATE >= TO_DATE('2019-02-01', 'yyyy-MM-dd') OR M.FIRST_NAME = 'Russell' OR M.LAST_NAME = 'Russell');



CREATE OR REPLACE VIEW empcount_view
AS
SELECT LOCATION_ID, DEPARTMENT_ID, EMP_COUNT
FROM DEPARTMENTS
         NATURAL JOIN
     (SELECT DEPARTMENT_ID, COUNT(*) EMP_COUNT FROM EMPLOYEES GROUP BY DEPARTMENT_ID HAVING COUNT(*) >= 2);



DROP INDEX DEPARTMENT_MANAGER_INDEX;
DROP INDEX LOCATION_COUNTRY_INDEX;

CREATE INDEX DEPARTMENT_MANAGER_INDEX ON DEPARTMENTS (MANAGER_ID);
CREATE INDEX LOCATION_COUNTRY_INDEX ON LOCATIONS (COUNTRY_ID);

SELECT DEPARTMENT_ID, DEPARTMENT_NAME
FROM DEPARTMENTS
         NATURAL JOIN
     (SELECT LOCATION_ID
      FROM LOCATIONS
               NATURAL JOIN
               (SELECT COUNTRY_ID FROM COUNTRIES WHERE REGION_ID = 2))
WHERE MANAGER_ID IS NOT NULL;