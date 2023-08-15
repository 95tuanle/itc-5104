Drop Table BMAJOR Cascade Constraints;
create table BMAJOR(    
MAJORId number(3) ,
   MAJORDesc varchar2(25));

 Alter table BMAJOR 
 Add constraint BMAJOR_MAJORid_pk
 PRIMARY KEY (MAJORid);

insert into BMAJOR values('100','Accounting');
insert into BMAJOR values('200','Computer Science');
insert into BMAJOR values('300','Business Inteligence');
insert into BMAJOR values('400','Data Analytics');
insert into BMAJOR values('500','Data Analytics');
insert into BMAJOR values('600','Telecommunications');


COMMIT;
-- 	To Create and insert into BCOURSE Table.....

Drop table BCOURSE Cascade Constraints;
create table BCOURSE(
   COURSEId varchar2(6),
   Title varchar2(20),
   Credits number(1),
   PreReq varchar2(10));

 Alter table BCOURSE
 ADD constraint BCOURSE_COURSEid
 PRIMARY KEY(COURSEid);

 Alter table BCOURSE
 ADD constraint BCOURSE_credits_check
 check(credits between 0 and 3);

insert into BCOURSE values('EN100','Basic English','0','');
insert into BCOURSE values('LA123','English Literature','3','EN100');
insert into BCOURSE values('CIS253','Database Systems','3','');
insert into BCOURSE values('CIS265','Systems Analysis','3','CIS253');
insert into BCOURSE values('MA150','College Algebra','3','');
insert into BCOURSE values('AC101','Accounting','3','');
insert into BCOURSE values('EC501','Economics','3','');
insert into BCOURSE values('BU1323','Business','3','');
commit;



--	To Create and insert data into BTERM Table.....

Drop table BTERM Cascade Constraints;
Create table BTERM(
   TERMid varchar2(4),
   TERMdesc varchar2(15),
   startdate date,
   enddate date);

Alter table BTERM  Add constraint  BTERM_TERMid_pk
 PRIMARY KEY(TERMid);

insert into BTERM values('SP21','Spring 2021',to_date('27-APR-2021','dd-MON-yyyy'),to_date('14-AUG-2021','dd-MON-yyyy'));
insert into BTERM values('FL21','Fall 2021',to_date('07-SEP-2021','dd-MON-yyyy'),to_date('18-DEC-2021','dd-MON-yyyy'));
insert into BTERM values('WN21','Winter 2021',to_date('04-JAN-2021','dd-MON-yyyy'),to_date('16-APR-2021','dd-MON-yyyy'));
insert into BTERM values('WN22','Winter 2022',to_date('10-JAN-2021','dd-MON-yyyy'),to_date('22-APR-2022','dd-MON-yyyy'));
commit;


--	To Create and insert data into BREGISTRATION Table......

Drop table BREGISTRATION Cascade Constraints;                               	 
create table BREGISTRATION(
   STUDENTId number(5),
   CsId number(4),
   Midterm_grade varchar2(1),
   Final_grade varchar2(1),
   Status varchar2(1));

 Alter table BREGISTRATION
 Add constraint regsid_csid_pk
 PRIMARY KEY (STUDENTid,csid);

insert into BREGISTRATION values('00100','1103','C','F','R');
insert into BREGISTRATION values('00100','1102','B','B','R');
insert into BREGISTRATION values('00100','1104','B','A','R');
insert into BREGISTRATION values('00102','1102','F','D','R');
insert into BREGISTRATION values('00102','1103','A','A','R');
insert into BREGISTRATION values('00103','1103','F','W','W');
insert into BREGISTRATION values('00103','1104','D','D','R');
insert into BREGISTRATION values('00100','1207','','','X');
insert into BREGISTRATION values('00103','1206','','','W');
insert into BREGISTRATION values('00104','1206','','','X');
insert into BREGISTRATION values('00104','1207','','','R');
insert into BREGISTRATION values('00104','1210','','','R');
insert into BREGISTRATION values('00105','1208','','','R');
insert into BREGISTRATION values('00105','1209','','','X');
insert into BREGISTRATION values('00101','1205','','','X');
insert into BREGISTRATION values('00102','1210','','','R');
insert into BREGISTRATION values('00102','1207','','','X');
insert into BREGISTRATION values('00102','1206','','','R');
commit;

-- 	To Creating BSTUDENT Table.....

Drop table BSTUDENT Cascade Constraints;
create table BSTUDENT(
   STUDENTid number(5),
   lastname varchar2(12),
   firstname varchar2(15),
   street varchar2(25),
   city varchar2(20),
   state char(2),
   zip number(5),
BIRTHDATE date,
     MAJORid number(3),
   phone number(10));

 Alter table BSTUDENT
 ADD constraint BSTUDENT_STUDENTid_pk
 PRIMARY KEY(STUDENTid);

insert into BSTUDENT values(00100,'Diaz','Jose','1 Ford Avenue #7','Hill','NJ',08863,to_date('12-JAN-00','dd-MON-RR'),'100',9735551111);
insert into BSTUDENT values(00101,'Tyler','Mickey','12 Morris Avenue','Bronx','NY','10486',to_date('18-MAR-99','dd-MON-RR'),'500','7185552222');
insert into BSTUDENT values(00102,'Patel','Rajesh','25 River Road #3','Edison','NJ','08837',to_date('12-DEC-01','dd-MON-RR'),'400','7325553333');
insert into BSTUDENT values(00103,'Rickels','Deborah','100 Main Street','Iselin','NJ','08838',to_date('20-OCT-99','dd-MON-RR'),'500','7325554444');
insert into BSTUDENT values(00104,'Lee','Brian','2845 First Lane','Hope','NY','11373',to_date('28-NOV-97','dd-MON-RR'),'600','2125555555');
insert into BSTUDENT values(00105,'Khan','Amir','213 Broadway','Clifton','NJ','07222',to_date('07-JUL-00','dd-MON-RR'),'200','2017585555');
commit;

-- 	To Create and insert data into BCRSSECTION Table.....

Drop table BCRSSECTION Cascade Constraints;
create table BCRSSECTION(
   csid number(4),
   COURSEid varchar2(10),
   section number(2),
   TERMid varchar2(4),
   FACULTYid number(3),
   day char(2),
   starttime varchar2(5),
   endtime varchar2(5),
   ROOMid number(2),
   maxcount number(2));

 Alter table BCRSSECTION
 ADD constraint BCRSSECTION_csid_pk
 PRIMARY KEY (csid);

insert into BCRSSECTION values('1101','CIS265','01','WN21','111','MW','09:00','10:30','13','30');
insert into BCRSSECTION values('1102','CIS253','01','WN21','123','TR','09:00','10:30','18','40');
insert into BCRSSECTION values('1103','MA150','02','WN21','444','F','09:00','12:00','15','25');
insert into BCRSSECTION values('1104','AC101','10','WN21','345','MW','10:30','12:00','16','35');
insert into BCRSSECTION values('1205','CIS265','02','SP21','','MW','09:00','10:30','14','35');
insert into BCRSSECTION values('1206','CIS265','02','SP21','111','TR','09:00','10:30','18','30');
insert into BCRSSECTION values('1207','LA123','05','SP21','','MW','09:00','10:30','15','30');
insert into BCRSSECTION values('1208','CIS253','21','SP21','123','TR','09:00','10:30','14','40');
insert into BCRSSECTION values('1209','EN100','11','SP21','111','MW','09:00','10:30','18','40');
insert into BCRSSECTION values('1210','CIS253','31','SP21','123','F','TBA','TBA','19','2');
commit;

Drop table BFACULTY Cascade Constraints;
create table BFACULTY(
  Facultyid number(4) Primary Key,
   FacultyName varchar2(20));

Insert Into BFACULTY values (111,'Jones');
Insert Into BFACULTY values (222,'Williams');
Insert Into BFACULTY values (123,'Mobley');
Insert Into BFACULTY values (235,'Venkat');
Insert Into BFACULTY values (345,'Sen');
Insert Into BFACULTY values (444,'Revera');
Insert Into BFACULTY values (555,'Chang');
Insert Into BFACULTY values (333,'Collins');
Commit;

-- -- Modify, add constraint, drop constraint, renaming a column

 Alter table BCOURSE modify COURSEid varchar2(7);
 Alter table BCOURSE modify COURSEid varchar2(10);
 Alter table BREGISTRATION add constraint regmidTERM_ck check (midterm_grade in ('A','B','C','D','F'));
 --Alter table BREGISTRATION add constraint reg_final_ck check (final_grade in ('A','B','C','D','F'));
--	To add the FOREIGN KEYS to the above tables

 alter table BREGISTRATION add constraint regSTUDENTid_fk foreign key(STUDENTid) references BSTUDENT(STUDENTid);

 alter table BREGISTRATION add constraint regcsid_fk foreign key(csid) references BCRSSECTION (csid);

 alter table BSTUDENT add constraint BSTUDENT_MAJORid_fk foreign key(MAJORid) references BMAJOR (MAJORid);

 alter table BCRSSECTION add constraint BCRSSECTION_Facultyid_fk foreign key(Facultyid) references BFACULTY(Facultyid);
 
 alter table BCRSSECTION add constraint BCRSSECTION_COURSEid_fk foreign key(COURSEid) references BCOURSE (COURSEid);

 alter table BCRSSECTION add constraint BCRSSECTION_TERMid_fk foreign key(TERMid) references BTERM (TERMid);

 
commit;

