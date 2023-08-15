DROP TABLE Purchase PURGE;
DROP TABLE EnterpriseOrder PURGE;
DROP TABLE Product PURGE;
DROP TABLE Supplier PURGE;
DROP TABLE City PURGE;

CREATE TABLE EnterpriseOrder (
    OrderID NUMBER(13) PRIMARY KEY,
    OrderDate DATE NOT NULL,
    CONSTRAINT CHK_OrderDate CHECK ( OrderDate >= TO_DATE('1970-01-01', 'YYYY-MM-DD') )
);

CREATE TABLE Purchase (
    OrderID NUMBER(13),
    ProductID NUMBER(10),
    CONSTRAINT PK_Purchase PRIMARY KEY ( OrderID, ProductID )
);

CREATE TABLE Product (
    ProductID NUMBER(10) PRIMARY KEY,
    Product VARCHAR2(30) DEFAULT 'Cars',
    SupplierID NUMBER(8) NOT NULL,
    Price NUMBER(10, 2) NOT NULL
);

CREATE TABLE Supplier (
    SupplierID NUMBER(8) PRIMARY KEY,
    Supplier VARCHAR2(30) UNIQUE NOT NULL,
    CityID NUMBER(5) NOT NULL
);

CREATE TABLE City (
    CityID NUMBER(5) PRIMARY KEY ,
    City VARCHAR2(30) NOT NULL,
    Population NUMERIC(8),
    CONSTRAINT CHK_City CHECK ( NOT REGEXP_LIKE(City, '[[:digit:]]') ),
    CONSTRAINT CHK_Population CHECK ( Population >= 0 )
);

ALTER TABLE Purchase
ADD CONSTRAINT FK_EnterpriseOrderPurchase
FOREIGN KEY (OrderID) REFERENCES EnterpriseOrder(OrderID);

ALTER TABLE Purchase
ADD CONSTRAINT FK_ProductPurchase
FOREIGN KEY (ProductID) REFERENCES Product(ProductID);

ALTER TABLE Product
ADD CONSTRAINT FK_SupplierProduct
FOREIGN KEY (SupplierID) REFERENCES Supplier(SupplierID);

ALTER TABLE Supplier
ADD CONSTRAINT FK_CitySupplier
FOREIGN KEY (CityID) REFERENCES City(CityID);