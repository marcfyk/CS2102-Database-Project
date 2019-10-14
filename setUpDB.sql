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
    password     varchar(100),
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
    country      varchar(100),
    Location     varchar(100),
    UNIQUE (country, location),
    FOREIGN KEY (country, location) REFERENCES Address(country, location),
    PRIMARY KEY (username, country, location)
);

ALTER TABLE Address
ADD CONSTRAINT C
FOREIGN KEY (country, location) REFERENCES HasAddress (country, location) DEFERRABLE INITIALLY DEFERRED;

CREATE TABLE CreditCard (
number     varchar(100) PRIMARY KEY,
exp         date
);
CREATE TABLE HasCreditCard (
    Username    varchar(100) REFERENCES Account(username),
    Number      varchar(100) REFERENCES CreditCard(number) UNIQUE,
    PRIMARY KEY (username, number)
);
ALTER TABLE CreditCard 
ADD CONSTRAINT C
FOREIGN KEY (number) REFERENCES HasCreditCard (number) DEFERRABLE INITIALLY DEFERRED;


CREATE TABLE Project (
    projectID        varchar(100),
    name            varchar(100) NOT NULL,
    creation_date    date NOT NULL,
    expiration_date    date NOT NULL,
    funds                 integer,
    rating         integer,
    PRIMARY KEY (projectID)
);

CREATE TABLE Product (
    productID varchar(100),
    projectID varchar(100) REFERENCES Project(projectID) ON DELETE CASCADE,
    productDescription text,
    productPrice numeric(7,2),
    PRIMARY KEY (productID, projectID)
);

CREATE TABLE Transaction (
    transactionID     serial,
    Username        varchar(100) REFERENCES Account(username) ON DELETE CASCADE,
    projectID         varchar(100) NOT NULL,
    productID        varchar(100) NOT NULL,
    Amount            integer,
    PRIMARY KEY (transactionID, username, projectID),
    FOREIGN KEY (projectID, productID) 
    REFERENCES Product (projectID, productID) ON DELETE CASCADE
);

CREATE TABLE Owns (
    Username     varchar(100) REFERENCES Account(username),
    projectID    varchar(100) REFERENCES Project(projectID),
    PRIMARY KEY (username, projectID)
);

ALTER TABLE Project
ADD CONSTRAINT C
FOREIGN KEY (projectID, name) REFERENCES Owns (projectID, username) DEFERRABLE INITIALLY DEFERRED;

CREATE TABLE Likes (
    Username     varchar(100) REFERENCES Account(username) ON DELETE CASCADE,
    projectID     varchar(100) REFERENCES Project(projectID) ON DELETE CASCADE,
    PRIMARY KEY (username, projectID)
);

CREATE TABLE Category (
    Name    varchar(100) PRIMARY KEY
);

CREATE TABLE Contains (    
    projectID     varchar(100) REFERENCES Project(projectID) ON DELETE CASCADE,
    Name         varchar(100) REFERENCES Category(name) ON DELETE CASCADE,
    PRIMARY KEY (projectID, name)
);

CREATE TABLE Interested (
    Username varchar(100) REFERENCES Account(username) ON DELETE CASCADE,
    Name     varchar(100) REFERENCES Category(name) ON DELETE CASCADE,
    PRIMARY KEY (Username, name)
);

CREATE TABLE Reviews (
    username varchar(100) REFERENCES Account(username) ON DELETE CASCADE,
    projectID     varchar(100) REFERENCES Project(projectID) ON DELETE CASCADE,
    Rating integer NOT NULL,
    Description    text,
    PRIMARY KEY (username, projectID),
    CHECK (RATING BETWEEN 1 AND 5)
);

CREATE OR REPLACE FUNCTION updateProjectData()
RETURNS TRIGGER AS 
$$ BEGIN
UPDATE Projects 
SET amount = (
    SELECT SUM(amount) 
    FROM Projects P 
    WHERE P.projectId = NEW.projectId
);
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER updateProjectTrigger
AFTER INSERT OR UPDATE ON Transaction
FOR EACH ROW
EXECUTE PROCEDURE updateProjectData();


CREATE OR REPLACE FUNCTION updateProjectReview() 
RETURNS TRIGGER AS
$$ BEGIN
WITH X as (
    SELECT AVG(reviews) as average 
    FROM Reviews
    WHERE NEW.projectID = Reviews.projectID
)
UPDATE Project
SET Project.rating = X.rating
WHERE projectID = NEW.projectID;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER projectReview
AFTER INSERT OR UPDATE ON Reviews
FOR EACH ROW
EXECUTE PROCEDURE updateProjectReview();


CREATE OR REPLACE FUNCTION checkDeleteAccount()
RETURNS TRIGGER AS
$$ BEGIN
IF (EXISTS (SELECT 1 FROM Owns O WHERE O.username = OLD.username)) THEN 
    RETURN NULL;
END IF;
RETURN OLD;
END; $$ LANGUAGE plpgsql;


CREATE TRIGGER deleteAccount
BEFORE DELETE ON Account
FOR EACH ROW
EXECUTE PROCEDURE checkDeleteAccount();


CREATE OR REPLACE FUNCTION checkDeleteAddress()
RETURNS TRIGGER AS
$$ BEGIN
IF ((SELECT COUNT(*) FROM HasAddress A WHERE OLD.country = A.country AND OLD.location = NEW.location) = 1) THEN
    DELETE FROM HasAddress A WHERE A.country = OLD.country AND A.location = OLD.location;
    DELETE FROM Address A WHERE A.country = OLD.country AND A.location = OLD.location;
END IF;
RETURN OLD;
END; $$ LANGUAGE plpgsql;


CREATE TRIGGER deleteAddress
AFTER DELETE ON HasAddress
FOR EACH ROW
EXECUTE PROCEDURE checkDeleteAddress();

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


