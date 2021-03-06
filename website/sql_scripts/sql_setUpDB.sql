DROP TABLE IF EXISTS Account CASCADE;
DROP TABLE IF EXISTS Follows CASCADE;
DROP TABLE IF EXISTS Address CASCADE;
DROP TABLE IF EXISTS HasAddress CASCADE;
DROP TABLE IF EXISTS CreditCard CASCADE;
DROP TABLE IF EXISTS HasCreditCard CASCADE;
DROP TABLE IF EXISTS Project CASCADE;
DROP TABLE IF EXISTS Product CASCADE;
DROP TABLE IF EXISTS Transaction CASCADE;
DROP TABLE IF EXISTS Owns CASCADE;
DROP TABLE IF EXISTS Category CASCADE;
DROP TABLE IF EXISTS Contains CASCADE;
DROP TABLE IF EXISTS Interested CASCADE;
DROP TABLE IF EXISTS Reviews CASCADE;
DROP TABLE IF EXISTS Likes CASCADE;

CREATE TABLE Account (
    username     varchar(100) PRIMARY KEY,
    password     varchar(100) NOT NULL,
    email         varchar(100) UNIQUE NOT NULL
);

CREATE TABLE Follows (
    follower     varchar(100) REFERENCES Account(username) ON DELETE CASCADE,
    followed     varchar(100) REFERENCES Account(username) ON DELETE CASCADE,
    PRIMARY KEY (follower, followed)
);

CREATE TABLE Address (
    country    varchar(100),
    location    varchar(100),
    PRIMARY KEY (country, location)
);

CREATE TABLE HasAddress (
    Username     varchar(100) REFERENCES Account(username),
    country      varchar(100) NOT NULL,
    Location     varchar(100) NOT NULL,
    FOREIGN KEY (country, location) REFERENCES Address(country, location),
    PRIMARY KEY (username, country, location)
);

CREATE TABLE CreditCard (
    number     varchar(16),
    exp        date NOT NULL,
    PRIMARY KEY(number),
    CHECK (LENGTH(number) = 16)
);

CREATE TABLE HasCreditCard (
    username    varchar(100) REFERENCES Account(username),
    number      varchar(100) REFERENCES CreditCard(number),
    PRIMARY KEY (username, number)
);

CREATE TABLE Project (
    projectID    integer,
    name            varchar(100) NOT NULL,
    creation_date    TIMESTAMPTZ DEFAULT Now() NOT NULL,
    expiration_date    date NOT NULL,
    goal            integer NOT NULL,
    funds        integer DEFAULT 0,
    rating         numeric DEFAULT 0,
    PRIMARY KEY (projectID),
    CHECK (creation_date < expiration_date)
);

CREATE TABLE Product (
    productID varchar(100),
    projectID integer REFERENCES Project(projectID) ON DELETE CASCADE,
    productDescription text,
    productPrice numeric(7,2),
    PRIMARY KEY (productID, projectID)
);


CREATE TABLE Transaction (
    transactionID   TIMESTAMPTZ DEFAULT Now() NOT NULL,
    Username        varchar(100) REFERENCES Account(username) ON DELETE CASCADE,
    projectID       integer NOT NULL,
    productID       varchar(100) NOT NULL,
    Amount          numeric(7, 2),
    PRIMARY KEY (transactionID, username, projectID, productID),
    FOREIGN KEY (projectID, productID) REFERENCES Product (projectID, productID),
    CHECK (NOT amount < 0)
);

CREATE TABLE Owns (
    username     varchar(100) REFERENCES Account(username),
    projectID    integer REFERENCES Project(projectID) ON DELETE CASCADE,
    PRIMARY KEY (username, projectID)
);

CREATE TABLE Likes (
    username     varchar(100) REFERENCES Account(username) ON DELETE CASCADE,
    projectID    integer REFERENCES Project (projectID) ON DELETE CASCADE,
    PRIMARY KEY (username, projectID)
);

CREATE TABLE Category (
    name    varchar(100) PRIMARY KEY
);

CREATE TABLE Contains (    
    projectID    integer REFERENCES Project (projectID) ON DELETE CASCADE,
    name         varchar(100) REFERENCES Category(name) ON DELETE CASCADE,
    PRIMARY KEY (projectID, name)
);

CREATE TABLE Interested (
    username varchar(100) REFERENCES Account(username) ON DELETE CASCADE,
    name     varchar(100) REFERENCES Category(name) ON DELETE CASCADE,
    PRIMARY KEY (Username, name)
);

CREATE TABLE Reviews (
    username     varchar(100) REFERENCES Account(username) ON DELETE CASCADE,
    projectID    integer REFERENCES Project(projectID) ON DELETE CASCADE,
    rating       integer NOT NULL,
    description  text,
    PRIMARY KEY (username, projectID),
    CHECK (RATING BETWEEN 1 AND 5)
);

CREATE TRIGGER checkTransaction
BEFORE INSERT ON Transaction
FOR EACH ROW
EXECUTE PROCEDURE checkTransactionFunction();

CREATE OR REPLACE FUNCTION checkTransactionFunction()
RETURNS TRIGGER AS $$
DECLARE projectID integer;
DECLARE transactionID TIMESTAMPTZ;
BEGIN
projectID := NEW.projectID;
transactionID := NEW.transactionID;
IF EXISTS (SELECT * FROM Project P WHERE P.projectID = NEW.projectID
    AND P.expiration_date::date < transactionID::date) THEN
RETURN NULL;
END IF;
RETURN NEW;
END; $$ LANGUAGE PLPGSQL;


CREATE TRIGGER checkAddress 
AFTER DELETE or UPDATE ON HasAddress
FOR EACH ROW 
EXECUTE PROCEDURE a();

CREATE OR REPLACE FUNCTION a()
RETURNS TRIGGER AS $$ 
DECLARE numOfAddressInUse integer;
BEGIN
numOfAddressInUse := COUNT(*) FROM HasAddress H
                      Where H.country = OLD.country AND H.location = OLD.location ;
IF(count = 0)
   THEN 
       DELETE FROM Address A
       WHERE A.location = OLD.country  AND A.country = OLD.country;
END IF;
RETURN NEW;
END; $$ LANGUAGE PLPGSQL;

CREATE TRIGGER createAddressTrigger
BEFORE INSERT OR UPDATE ON HasAddress
FOR EACH ROW
EXECUTE PROCEDURE createAddress();

CREATE OR REPLACE FUNCTION createAddress()
RETURNS TRIGGER AS
$$
BEGIN
IF(NOT EXISTS(SELECT A.location, A.country
          FROM Address A
          WHERE A.location = NEW. location AND A.country = NEW.country))
THEN
   INSERT INTO Address VALUES(NEW.country,NEW.location);
END IF;
RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updateFunding()
RETURNS TRIGGER AS
$$ BEGIN
IF (EXISTS (SELECT 1 FROM Transaction T WHERE T.projectID = NEW.projectID)) THEN
UPDATE project
SET funds = (SELECT SUM(amount) FROM Transaction T WHERE T.projectID = NEW.projectID)
FROM Project P
WHERE P.projectID = NEW.projectID;
RETURN NEW;
END IF;
UPDATE project
SET funds = 0
FROM Project P
WHERE P.projectID = NEW.projectID;
RETURN NEW;
END; $$ LANGUAGE plpgsql;
 
CREATE TRIGGER updateFunds 
AFTER INSERT OR UPDATE OR DELETE ON Transaction 
FOR EACH ROW
EXECUTE FUNCTION updateFunding();

CREATE OR REPLACE FUNCTION updateProjectReview() 
RETURNS TRIGGER AS $$
BEGIN
IF (EXISTS (SELECT 1 FROM Reviews WHERE NEW.projectID = projectID)) THEN
UPDATE Project P
SET rating = (SELECT AVG(rating) as average FROM Reviews R WHERE NEW.projectID = R.projectID)
WHERE P.projectID = NEW.projectID;
RETURN NEW;
END IF;
UPDATE Project P
SET rating = 0
WHERE P.projectID = NEW.projectID;
RETURN NEW;
END; $$ LANGUAGE plpgsql;
 
CREATE TRIGGER projectReview
AFTER INSERT OR UPDATE OR DELETE ON Reviews
FOR EACH ROW
EXECUTE PROCEDURE updateProjectReview();

CREATE OR REPLACE FUNCTION checkDeleteAccount()
RETURNS TRIGGER AS 
$$ BEGIN
IF (EXISTS (SELECT 1 FROM Owns O, Project P
    WHERE O.username = OLD.username
    AND NOW() < P.expiration_date)) THEN 
RETURN NULL;
END IF;
RETURN NEW;
END; $$ LANGUAGE plpgsql;
 
 
CREATE TRIGGER deleteAccount
BEFORE DELETE ON Account
FOR EACH ROW
EXECUTE PROCEDURE checkDeleteAccount();


CREATE OR REPLACE FUNCTION checkDeleteCreditCard()
RETURNS TRIGGER AS
$$ BEGIN
IF ((SELECT COUNT(*) FROM HasCreditCard C WHERE OLD.number = C.number) = 1) THEN
    DELETE FROM CreditCard C WHERE C.number = OLD.number;
    DELETE FROM HasCreditCard C WHERE C.number = OLD.number;
END IF;
RETURN OLD;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER deleteCreditCard
AFTER DELETE ON HasCreditCard
FOR EACH ROW
EXECUTE PROCEDURE checkDeleteCreditCard();

CREATE OR REPLACE FUNCTION setUpAcct(username varchar, email varchar, password varchar, country varchar, location varchar, ccNumber varchar, exp date) RETURNS VOID AS $$

DECLARE address boolean;
DECLARE CC boolean;

BEGIN

INSERT INTO ACCOUNT VALUES (username, password, email);

IF( country IS NOT NULL AND location IS NOT NULL AND ccNumber IS NOT NULL AND exp IS NOT NULL) 

 THEN
      address := EXISTS( SELECT A.country, A.location
              FROM Address A
              WHERE country = A.country AND location = A.location); 
        CC := EXISTS ( SELECT cc.Number , cc.exp
                       FROM CreditCard cc
                       WHERE Number = cc.number AND exp = cc.exp );
IF(address AND CC) 
   THEN 
       INSERT INTO  HasCreditCard VALUES(username, number);
       INSERT INTO HasAddress VALUES(username, country, location);

   ELSIF (address)
      THEN
        INSERT INTO CreditCard VALUES(number, exp);
        INSERT INTO  HasCreditCard VALUES(username, number);      
        INSERT INTO HasAddress VALUES(username, country, location);

          
          ELSIF (CC) 
       THEN
         INSERT INTO Address VALUES(country, location);
         INSERT INTO HasAddress VALUES(username, country, location);
         INSERT INTO  HasCreditCard VALUES(username, number); 
 END IF;

ELSIF(country IS NOT NULL AND location IS NOT NULL) 
    THEN
       address := EXISTS( SELECT A.country, A.location
              FROM Address A
              WHERE country = A.country AND location = A.location); 
       IF(address)
           THEN 
             INSERT INTO HasAddress VALUES(username, country, location);
        ELSE 
          INSERT INTO Address VALUES(country, location);
         INSERT INTO HasAddress VALUES(username, country, location); 
       END IF;
ELSIF( ccNumber IS NOT NULL AND exp IS NOT NULL)
    THEN
       CC := EXISTS ( SELECT cc.Number , cc.exp
                       FROM CreditCard cc
                       WHERE Number = cc.number AND exp = cc.exp);
         IF(cc)
         THEN 
            INSERT INTO  HasCreditCard VALUES(username, number);
         ELSE 
            INSERT INTO CreditCard VALUES(number, exp);
      INSERT INTO  HasCreditCard VALUES(username, number);  
            END IF;
END IF;   
COMMIT; 
      END; $$ LANGUAGE PLPGSQL;


INSERT INTO Account(username, password, email) VALUES('john_connor', 'password', 'jconnor@email.com');
INSERT INTO Account(username, password, email) VALUES('obama_b', 'password', 'obama@email.com');
INSERT INTO Account(username, password, email) VALUES('fiddle_player', 'password', 'fiddle@email.com');
INSERT INTO Account(username, password, email) VALUES('georgia_boi', 'password', 'georgia@email.com');
INSERT INTO Account(username, password, email) VALUES('panadol_overdose', 'password', 'panadol@email.com');
INSERT INTO Account(username, password, email) VALUES('table_legs', 'password', 'table@email.com');
INSERT INTO Account(username, password, email) VALUES('sony_is', 'password', 'sony@email.com');
INSERT INTO Account(username, password, email) VALUES('not_a_sponsor', 'password', 'is_a_sponsor@email.com');
INSERT INTO Account(username, password, email) VALUES('water_bottle', 'password', 'mug@email.com');
INSERT INTO Account(username, password, email) VALUES('hydrohomie', 'password', 'hydrophobic@email.com');
INSERT INTO Account(username, password, email) VALUES('type_a_plug', 'password', 'type_b_plug@email.com');
INSERT INTO Account(username, password, email) VALUES('soc_printer', 'password', 'fass_printer@email.com');
INSERT INTO Account(username, password, email) VALUES('whiteboard_marker', 'password', 'chalk@email.com');
INSERT INTO Account(username, password, email) VALUES('why_utown_so_crowded', 'password', 'hangout@email.com');
INSERT INTO Account(username, password, email) VALUES('1234', '1234', '1234@email.com');
INSERT INTO Account(username, password, email) VALUES('happy', 'iMHappy', 'happy@gmail.com');
INSERT INTO Account(username, password, email) VALUES('sad' , 'iMSad', 'sad@gmail.com');
INSERT INTO Follows(follower, followed) VALUES('john_connor', 'obama_b');
INSERT INTO Follows(follower, followed) VALUES('fiddle_player', 'obama_b');
INSERT INTO Follows(follower, followed) VALUES('georgia_boi', 'obama_b');
INSERT INTO Follows(follower, followed) VALUES('hydrohomie', 'obama_b');
INSERT INTO Follows(follower, followed) VALUES('why_utown_so_crowded', '1234');
INSERT INTO Follows(follower, followed) VALUES('table_legs', '1234');
INSERT INTO Follows(follower, followed) VALUES('sony_is', '1234');
INSERT INTO Follows(follower, followed) VALUES('not_a_sponsor', '1234');
INSERT INTO Follows(follower, followed) VALUES('type_a_plug', '1234');
INSERT INTO Follows(follower, followed) VALUES('hydrohomie', '1234');
INSERT INTO Follows(follower, followed) VALUES('not_a_sponsor', 'table_legs');
INSERT INTO Follows(follower, followed) VALUES('panadol_overdose', 'table_legs');
INSERT INTO Follows(follower, followed) VALUES('georgia_boi', 'table_legs');
INSERT INTO Follows(follower, followed) VALUES('1234', 'table_legs');
INSERT INTO Follows(follower, followed) VALUES('soc_printer', 'table_legs');
INSERT INTO Follows(follower, followed) VALUES('hydrohomie', 'fiddle_player');
INSERT INTO Follows(follower, followed) VALUES('obama_b', 'fiddle_player');
INSERT INTO Follows(follower, followed) VALUES('happy', 'sad');


INSERT INTO Address(country, location) VALUES('Singapore', '20 Street, 999999');
INSERT INTO Address(country, location) VALUES('United States', '20 Street, 999999');
INSERT INTO Address(country, location) VALUES('Dominican Republic', '20 Street, 999999');
INSERT INTO Address(country, location) VALUES('Denmark', '20 Street, 999999');
INSERT INTO Address(country, location) VALUES('Poland', '20 Street, 999999');
INSERT INTO Address(country, location) VALUES('Malaysia', '20 Street, 999999');
INSERT INTO Address(country, location) VALUES('Sealand', '20 Street, 999999');
INSERT INTO Address(country, location) VALUES('United Kingdom', '20 Street, 999999');
INSERT INTO Address(country, location) VALUES('Soviet Russia', '20 Street, 999999');
INSERT INTO Address(country, location) VALUES('Cambodia', '20 Street, 999999');
INSERT INTO Address(country, location) VALUES('Atlantica', '20 Street, 999999');
INSERT INTO Address(country, location) VALUES('Gotham', '20 Street, 999999');
INSERT INTO Address(country, location) VALUES('Singapore', '20 Street 999998');
INSERT INTO Address(country, location) VALUES('United States', '20 Street 999998');

INSERT INTO HasAddress(username, country, location) VALUES('happy' , 'United States' , '20 Street 999998');
INSERT INTO HasAddress(username, country, location) VALUES('sad' , 'Singapore' , '20 Street 999998');
INSERT INTO HasAddress(username, country, location) VALUES('john_connor', 'Singapore', '20 Street, 999999');
INSERT INTO HasAddress(username, country, location) VALUES('obama_b', 'United States', '20 Street, 999999');
INSERT INTO HasAddress(username, country, location) VALUES('why_utown_so_crowded', 'Dominican Republic', '20 Street, 999999');
INSERT INTO HasAddress(username, country, location) VALUES('hydrohomie', 'Denmark', '20 Street, 999999');
INSERT INTO HasAddress(username, country, location) VALUES('fiddle_player', 'Poland', '20 Street, 999999');
INSERT INTO HasAddress(username, country, location) VALUES('whiteboard_marker', 'Malaysia', '20 Street, 999999');
INSERT INTO HasAddress(username, country, location) VALUES('1234', 'Sealand', '20 Street, 999999');
INSERT INTO HasAddress(username, country, location) VALUES('table_legs', 'United Kingdom', '20 Street, 999999');
INSERT INTO HasAddress(username, country, location) VALUES('sony_is', 'Soviet Russia', '20 Street, 999999');
INSERT INTO HasAddress(username, country, location) VALUES('not_a_sponsor', 'Cambodia', '20 Street, 999999');
INSERT INTO HasAddress(username, country, location) VALUES('georgia_boi', 'Atlantica', '20 Street, 999999');
INSERT INTO HasAddress(username, country, location) VALUES('water_bottle', 'Gotham', '20 Street, 999999');

INSERT INTO CreditCard(number, exp) VALUES(2000000000000000, '2019-12-01');
INSERT INTO CreditCard(number, exp) VALUES(1000000000000000, '2019-12-01');
INSERT INTO CreditCard(number, exp) VALUES(1111111111111111, '2019-12-01');
INSERT INTO CreditCard(number, exp) VALUES(2222222222222222, '2020-11-01');
INSERT INTO CreditCard(number, exp) VALUES(3333333333333333, '2019-10-01');
INSERT INTO CreditCard(number, exp) VALUES(4444444444444444, '2020-09-01');
INSERT INTO CreditCard(number, exp) VALUES(5555555555555555, '2019-08-01');
INSERT INTO CreditCard(number, exp) VALUES(6666666666666666, '2020-07-01');
INSERT INTO CreditCard(number, exp) VALUES(7777777777777777, '2019-06-01');
INSERT INTO CreditCard(number, exp) VALUES(8888888888888888, '2020-05-01');
INSERT INTO CreditCard(number, exp) VALUES(9999999999999999, '2019-04-01');
INSERT INTO CreditCard(number, exp) VALUES(1212121212121212, '2020-03-01');
INSERT INTO CreditCard(number, exp) VALUES(3434343434343434, '2019-02-01');
INSERT INTO CreditCard(number, exp) VALUES(5656565656565656, '2020-01-01');
INSERT INTO CreditCard(number, exp) VALUES(7878787878787878, '2019-12-01');

INSERT INTO HasCreditCard(username, number) VALUES('happy', 2000000000000000);
INSERT INTO HasCreditCard(username, number) VALUES('sad', 1000000000000000);
INSERT INTO HasCreditCard(username, number) VALUES('john_connor', 1111111111111111);
INSERT INTO HasCreditCard(username, number) VALUES('obama_b', 2222222222222222);
INSERT INTO HasCreditCard(username, number) VALUES('fiddle_player', 3333333333333333);
INSERT INTO HasCreditCard(username, number) VALUES('georgia_boi', 4444444444444444);
INSERT INTO HasCreditCard(username, number) VALUES('panadol_overdose', 5555555555555555);
INSERT INTO HasCreditCard(username, number) VALUES('table_legs', 6666666666666666);
INSERT INTO HasCreditCard(username, number) VALUES('sony_is', 7777777777777777);
INSERT INTO HasCreditCard(username, number) VALUES('not_a_sponsor', 8888888888888888);
INSERT INTO HasCreditCard(username, number) VALUES('water_bottle', 9999999999999999);
INSERT INTO HasCreditCard(username, number) VALUES('hydrohomie', 1212121212121212);
INSERT INTO HasCreditCard(username, number) VALUES('type_a_plug', 3434343434343434);
INSERT INTO HasCreditCard(username, number) VALUES('whiteboard_marker', 5656565656565656);
INSERT INTO HasCreditCard(username, number) VALUES('1234', 7878787878787878);

INSERT INTO Project(projectId, name, creation_date, expiration_date, goal, funds)
    VALUES(1, 'Self-Cleaning Water Bottle', '2019-11-09', '2020-12-01', 20000, 0);
INSERT INTO Project(projectId, name, creation_date, expiration_date, goal, funds)
    VALUES(2, 'Amazing Mouse', '2019-11-09', '2020-12-01', 1000, 0);
INSERT INTO Project(projectId, name, creation_date, expiration_date, goal, funds)
    VALUES(3, '$50 Stupendous Kitchen Rags', '2019-11-09', '2020-12-01', 1000, 0);
INSERT INTO Project(projectId, name, creation_date, expiration_date, goal, funds)
    VALUES(4, 'Donald Trumps Comb', '2019-11-09', '2020-12-01', 10, 0);
INSERT INTO Project(projectId, name, creation_date, expiration_date, goal, funds)
    VALUES(5, 'Japanese Notebook', '2019-11-09', '2020-12-01', 10000, 0);
INSERT INTO Project(projectId, name, creation_date, expiration_date, goal, funds)
    VALUES(6, 'Intel 9nm Chipset', '2019-11-09', '2020-12-01', 12342, 0);
INSERT INTO Project(projectId, name, creation_date, expiration_date, goal, funds)
    VALUES(7, 'Smart Table Scam', '2019-11-09', '2020-12-01', 10000, 0);
INSERT INTO Project(projectId, name, creation_date, expiration_date, goal, funds)
    VALUES(8, 'Pencilcase woven with threads from Tibetan Yak Hairs', '2019-11-09', '2020-12-01', 5000, 0);
INSERT INTO Project(projectId, name, creation_date, expiration_date, goal, funds)
    VALUES(9, '1000pc Printer Paper', '2019-11-09', '2020-12-01', 42420, 0);
INSERT INTO Project(projectId, name, creation_date, expiration_date, goal, funds)
    VALUES(10, 'hiCards', '2019-11-09', '2020-12-01', 20000, 0);
INSERT INTO Project(projectId, name, creation_date, expiration_date, goal, funds)
    VALUES(11, 'byeCards', '2019-11-09', '2020-12-01', 200, 0);

INSERT INTO Product(productId, projectId, productDescription, productPrice)
    VALUES(1, 1, 'An amazing self-cleaning water bottle!!!', 100);
INSERT INTO Product(productId, projectId, productDescription, productPrice)
    VALUES(2, 2, 'Finalmouse 2016 - up your game with this amazing mouse.', 250);
INSERT INTO Product(productId, projectId, productDescription, productPrice)
    VALUES(3, 3, 'The kleenex killer, get your $50 overpriced kitchen rags today!', 51);
INSERT INTO Product(productId, projectId, productDescription, productPrice)
    VALUES(4, 4, 'Make yourself look as fabulous as Donald Trump for only $1', 1);
INSERT INTO Product(productId, projectId, productDescription, productPrice)
    VALUES(5, 5, 'Made from the trees from Nagasaki', 20);
INSERT INTO Product(productId, projectId, productDescription, productPrice)
    VALUES(6, 6, 'If only Intel stopped working on 14nm', 600);
INSERT INTO Product(productId, projectId, productDescription, productPrice)
    VALUES(7, 7, 'Lets you use an app to control your table - so smart!', 10000);
INSERT INTO Product(productId, projectId, productDescription, productPrice)
    VALUES(8, 8, 'Only the most durable threads from Tibetan Yak Hairs are used to create this pencilcase', 100);
INSERT INTO Product(productId, projectId, productDescription, productPrice)
    VALUES(9, 9, 'An amazing self-cleaning water bottle!!!', 100);
INSERT INTO Product(productId, projectId, productDescription, productPrice)
    VALUES(10, 10, 'bye cards', 10);
INSERT INTO Product(productId, projectId, productDescription, productPrice)
    VALUES(11, 11, 'hi cards', 10);

INSERT INTO Owns(username, projectId) VALUES('hydrohomie', 1);
INSERT INTO Owns(username, projectId) VALUES('obama_b', 2);
INSERT INTO Owns(username, projectId) VALUES('table_legs', 3);
INSERT INTO Owns(username, projectId) VALUES('soc_printer', 4);
INSERT INTO Owns(username, projectId) VALUES('whiteboard_marker', 5);
INSERT INTO Owns(username, projectId) VALUES('1234', 6);
INSERT INTO Owns(username, projectId) VALUES('water_bottle', 7);
INSERT INTO Owns(username, projectId) VALUES('sony_is', 8);
INSERT INTO Owns(username, projectId) VALUES('john_connor', 9);
INSERT INTO Owns(username, projectId) VALUES('happy', 10);
INSERT INTO Owns(username, projectId) VALUES('sad', 11);

INSERT INTO Transaction(username, projectId, productId, amount)
    VALUES('hydrohomie', 2, 2, 995);
INSERT INTO Transaction(username, projectId, productId, amount)
    VALUES('obama_b', 2, 2, 10000);
INSERT INTO Transaction(username, projectId, productId, amount)
    VALUES('1234', 2, 2, 500);
INSERT INTO Transaction(username, projectId, productId, amount)
    VALUES('table_legs', 7, 7, 20000);
INSERT INTO Transaction(username, projectId, productId, amount)
    VALUES('soc_printer', 8, 8, 100);
INSERT INTO Transaction(username, projectId, productId, amount)
    VALUES('happy', 2, 2, 10000);
INSERT INTO Transaction(username, projectId, productId, amount)
    VALUES('sad', 2, 2, 10000);
INSERT INTO Transaction(username, projectId, productId, amount)
    VALUES('georgia_boi', 2, 2, 10000);

INSERT INTO Likes(username, projectId) VALUES('hydrohomie', 1);
INSERT INTO Likes(username, projectId) VALUES('water_bottle', 1);
INSERT INTO Likes(username, projectId) VALUES('hydrohomie', 2);
INSERT INTO Likes(username, projectId) VALUES('obama_b', 2);
INSERT INTO Likes(username, projectId) VALUES('1234', 2);
INSERT INTO Likes(username, projectId) VALUES('fiddle_player', 3);
INSERT INTO Likes(username, projectId) VALUES('john_connor', 3);
INSERT INTO Likes(username, projectId) VALUES('type_a_plug', 4);
INSERT INTO Likes(username, projectId) VALUES('why_utown_so_crowded', 4);
INSERT INTO Likes(username, projectId) VALUES('panadol_overdose', 4);
INSERT INTO Likes(username, projectId) VALUES('georgia_boi', 5);
INSERT INTO Likes(username, projectId) VALUES('whiteboard_marker', 5);
INSERT INTO Likes(username, projectId) VALUES('obama_b', 5);
INSERT INTO Likes(username, projectId) VALUES('john_connor', 6);
INSERT INTO Likes(username, projectId) VALUES('fiddle_player', 6);
INSERT INTO Likes(username, projectId) VALUES('table_legs', 6);
INSERT INTO Likes(username, projectId) VALUES('fiddle_player', 7);
INSERT INTO Likes(username, projectId) VALUES('not_a_sponsor', 8);
INSERT INTO Likes(username, projectId) VALUES('sony_is', 9);

INSERT INTO Category(name) VALUES('Office Accessories');
INSERT INTO Category(name) VALUES('Electronics');
INSERT INTO Category(name) VALUES('Tools');
INSERT INTO Category(name) VALUES('Furniture');
INSERT INTO Category(name) VALUES('PMDs');
INSERT INTO Category(name) VALUES('Fashion');
INSERT INTO Category(name) VALUES('Stationery');
INSERT INTO Category(name) VALUES('Beauty Products');
INSERT INTO Category(name) VALUES('EDC');
INSERT INTO Category(name) VALUES('Obvious Scam');

INSERT INTO Contains(projectId, name) VALUES(1, 'Tools');
INSERT INTO Contains(projectId, name) VALUES(2, 'Electronics');
INSERT INTO Contains(projectId, name) VALUES(3, 'Tools');
INSERT INTO Contains(projectId, name) VALUES(4, 'Fashion');
INSERT INTO Contains(projectId, name) VALUES(4, 'Beauty Products');
INSERT INTO Contains(projectId, name) VALUES(5, 'Stationery');
INSERT INTO Contains(projectId, name) VALUES(6, 'Electronics');
INSERT INTO Contains(projectId, name) VALUES(7, 'Obvious Scam');
INSERT INTO Contains(projectId, name) VALUES(8, 'EDC');
INSERT INTO Contains(projectId, name) VALUES(8, 'Stationery');
INSERT INTO Contains(projectId, name) VALUES(9, 'Office Accessories');
INSERT INTO Contains(projectId, name) VALUES(9, 'Stationery');

INSERT INTO Interested(username, name) VALUES('john_connor', 'PMDs');
INSERT INTO Interested(username, name) VALUES('obama_b', 'Office Accessories');
INSERT INTO Interested(username, name) VALUES('obama_b', 'Electronics');
INSERT INTO Interested(username, name) VALUES('fiddle_player', 'Furniture');
INSERT INTO Interested(username, name) VALUES('fiddle_player', 'EDC');
INSERT INTO Interested(username, name) VALUES('georgia_boi', 'Fashion');
INSERT INTO Interested(username, name) VALUES('panadol_overdose', 'Tools');
INSERT INTO Interested(username, name) VALUES('panadol_overdose', 'Electronics');
INSERT INTO Interested(username, name) VALUES('table_legs', 'Obvious Scam');
INSERT INTO Interested(username, name) VALUES('table_legs', 'EDC');
INSERT INTO Interested(username, name) VALUES('sony_is', 'Office Accessories');
INSERT INTO Interested(username, name) VALUES('not_a_sponsor', 'Office Accessories');
INSERT INTO Interested(username, name) VALUES('water_bottle', 'Tools');
INSERT INTO Interested(username, name) VALUES('hydrohomie', 'Tools');
INSERT INTO Interested(username, name) VALUES('hydrohomie', 'Fashion');
INSERT INTO Interested(username, name) VALUES('type_a_plug', 'EDC');
INSERT INTO Interested(username, name) VALUES('soc_printer', 'Tools');
INSERT INTO Interested(username, name) VALUES('soc_printer', 'Beauty Products');
INSERT INTO Interested(username, name) VALUES('whiteboard_marker', 'Stationery');
INSERT INTO Interested(username, name) VALUES('whiteboard_marker', 'Beauty Products');
INSERT INTO Interested(username, name) VALUES('why_utown_so_crowded', 'EDC');
INSERT INTO Interested(username, name) VALUES('why_utown_so_crowded', 'Stationery');
INSERT INTO Interested(username, name) VALUES('1234', 'Electronics');
INSERT INTO Interested(username, name) VALUES('1234', 'Obvious Scam');

INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('john_connor', 1, 5, 'Simply Terrible');
INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('obama_b', 2, 1, 'This has nothing on my stimulus package');
INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('obama_b', 6, 2, 'We need to sponsor foreign aid.');
INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('fiddle_player', 7, 5, 'Its a scam, I love it');
INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('fiddle_player', 5, 4, 'Does not play a fiddle, dont like it');
INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('georgia_boi', 9, 3, 'Straight outta georgia');
INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('panadol_overdose', 4, 4, 'For republicans, by republicans, 10/10 IGN');
INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('panadol_overdose', 8, 1, 'I lose my pencilcase so I tried this. Its coarse, rough, and gets everywhere, I hate it');
INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('table_legs', 7, 3, 'Doesnt support my legs, 4/10');
INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('table_legs', 2, 2, 'Doesnt support my legs, 3/10');
INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('sony_is', 1, 5, 'Was alright I guess');
INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('not_a_sponsor', 5, 5, 'This post was made by JAPAN gang.');
INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('water_bottle', 1, 3, 'Visit WaterBottleMemes.com');
INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('hydrohomie', 1, 5, 'Perfect for every hydrohomie');
INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('hydrohomie', 4, 3, 'The comb that will pierce the heavens');
INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('type_a_plug', 9, 4, 'Going to use this to make my full-bridge rectifier.');
INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('soc_printer', 6, 2, 'Generic comment number 1');
INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('soc_printer', 3, 4, 'Generic comment number 2');
INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('whiteboard_marker', 5, 2, 'Generic comment number 3');
INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('whiteboard_marker', 6, 5, 'Generic comment number 4');
INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('why_utown_so_crowded', 8, 4, 'Generic comment number 5');
INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('why_utown_so_crowded', 9, 1, 'Generic comment number 6');
INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('1234', 2, 3, 'Generic comment number 7');
INSERT INTO Reviews(username, projectId, rating, description)
    VALUES('1234', 3, 2, 'Generic comment number 8');
