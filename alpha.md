# Alpha

## Complex Queries
1. Leaderboards
2. Generate homepage view
3. Recommend popular projects based on followed accounts
4. Viewing customers that actively support your projects

## Triggers
1. On `INSERT | UPDATE | DELETE` into `Transaction`, update `Project.amount` by calculating the new net amount
2. On `INSERT | UPDATE | DELETE` into `Review`, update `Project.rating` by calculating the average rating
3. On `DELETE` in `Account`, prevent deletion if account has an active project by checking `Owns`

## Schema

### Overview
- [Account](#account)
- [Follows](#follows)
- [Address](#address)
- [HasAddress](#hasaddress)
- [CreditCard](#creditcard)
- [HasCreditCard](#hascreditcard)
- [Project](#project)
- [Products](#products)
- [Transaction](#transaction)
- [Owns](#owns)
- [Likes](#likes)
- [Category](#category)
- [Contains](#contains)
- [Interested](#interested)
- [Reviews](#reviews)

#### <a name="account"></a> Account
```
CREATE TABLE Account (
    username     varchar(100) PRIMARY KEY,
    password     varchar(100),
    email         varchar(100) UNIQUE NOT NULL
);
```
#### <a name="follows"></a> Follows
```
CREATE TABLE Follows (
    follower     varchar(100) REFERENCES Account(username) ON DELETE CASCADE,
    followed     varchar(100) REFERENCES Account(username) ON DELETE CASCADE,
    PRIMARY KEY (follower, followed)
);

```
#### <a name="address"></a> Address
```
CREATE TABLE Address (
    country    varchar(100) NOT NULL,
    location    varchar(100) NOT NULL,
    PRIMARY KEY (country, location)
);

ALTER TABLE Address
ADD CONSTRAINT C
FOREIGN KEY (country, location) REFERENCES HasAddress (country, location) DEFERRABLE INITIALLY DEFERRED;
```
#### <a name="hasaddress"></a> HasAddress
```
CREATE TABLE HasAddress (
    Username     varchar(100) REFERENCES Account(username),
country     varchar(100) REFERENCES Address(country),
Location     varchar(100) REFERENCES Address(location)
);
```
#### <a name="creditcard"></a> CreditCard
```
CREATE TABLE CreditCard (
number     varchar(100) NOT NULL,
exp         date,
PRIMARY KEY (number)
);
```
#### <a name="hascreditcard"></a> HasCreditCard
```
CREATE TABLE CreditCard (
number     varchar(100) NOT NULL,
exp         date,
PRIMARY KEY (number)
);
ALTER TABLE CreditCard 
ADD CONSTRAINT C
FOREIGN KEY (number) REFERENCES HasCreditCard (number) DEFERRABLE INITIALLY DEFERRED;
```
#### <a name="project"></a> Project
```
CREATE TABLE Project (
    projectID        varchar(100),
    name            varchar(100) NOT NULL,
    creation_date    date NOT NULL,
    expiration_date    date NOT NULL,
      funds                 integer,
      rating         integer,
    PRIMARY KEY (projectID)
);
```
#### <a name="products"></a> Products
```
CREATE TABLE Product (
productID varchar(100),
projectID varchar(100) REFERENCES Project(projectID) ON DELETE CASCADE,
productDescription text,
productPrice numeric(7,2),
PRIMARY KEY (productID, projectID)
);
```
#### <a name="transaction"></a> Transaction
```
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
```
#### <a name="owns"></a> Owns
```
CREATE TABLE Owns (
    Username     varchar(100) REFERENCES Account(username),
    projectID    varchar(100) REFERENCES Project(projectID),
    PRIMARY KEY (username, projectID)
);

ALTER TABLE Project
ADD CONSTRAINT C
FOREIGN KEY (projectID, name) REFERENCES Owns (projectID, username) DEFERRABLE INITIALLY DEFERRED;
```
#### <a name="likes"></a> Likes
```
CREATE TABLE Likes (
    Username     varchar(100) REFERENCES Account(username) ON DELETE CASCADE,
    projectID     varchar(100) REFERENCES Project(projectID) ON DELETE CASCADE,
    PRIMARY KEY (username, projectID)
);
```
#### <a name="category"></a> Category
```
CREATE TABLE Category (
    Name    varchar(100) PRIMARY KEY
);
```
#### <a name="contains"></a> Contains
```
CREATE TABLE Contains (    
    projectID     varchar(100) REFERENCES Project(projectID) ON DELETE CASCADE,
    Name         varchar(100) REFERENCES Category(name) ON DELETE CASCADE,
    PRIMARY KEY (projectID, name)
);
```
#### <a name="interested"></a> Interested
```
CREATE TABLE Interested (
    Username varchar(100) REFERENCES Account(username) ON DELETE CASCADE,
Name     varchar(100) REFERENCES Category(name) ON DELETE CASCADE,
PRIMARY KEY (Username, name)
);
```
#### <a name="reviews"></a> Reviews
```
CREATE TABLE Reviews (
    username varchar(100) REFERENCES Account(username) ON DELETE CASCADE,
projectID     varchar(100) REFERENCES Project(projectID) ON DELETE CASCADE,
Rating integer NOT NULL,
Description    text,
    PRIMARY KEY (username, projectID),
CHECK (RATING BETWEEN 1 AND 5)
);
```

###