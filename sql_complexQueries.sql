/* Query 1: Obsession */
WITH Y AS (
    SELECT username, COUNT(projectId)
    FROM Owns
    GROUP BY username
),
X AS (
    SELECT DISTINCT
        O.username AS owner,
        O.projectId AS projectId,
        T.username AS buyer
    FROM Owns O, Transaction T
    WHERE O.projectId = T.projectId
)
SELECT *
FROM X INNER JOIN Y
ON X.buyer = Y.username
AND Y.count = (
    SELECT COUNT(Z.projectId)
    FROM X Z
    WHERE Z.owner = X.owner
    AND Z.buyer = X.buyer
);

/* Query 2: most international owners */
WITH X AS (
    SELECT Owns.username AS owner, Transaction.projectId, HasAddress.country
    FROM Owns, Transaction, HasAddress
    WHERE Owns.projectId = Transaction.projectId
    AND Transaction.username = HasAddress.username
)
SELECT owner
FROM X
GROUP BY owner
HAVING COUNT(country) > ALL(SELECT COUNT(country) FROM X);

/* Query 3: most international owners */
WITH X AS (
    SELECT O.username, SUM(P.funds), AVG(P.funds)
    FROM Owns O NATURAL JOIN Project P
    GROUP BY O.username
),
Y AS (
    SELECT X.username
    FROM X
    ORDER BY SUM, AVG
)
SELECT *
FROM Y y1, Y y2
WHERE (y1.username, y2.username) IN (
    SELECT F1.followed, F2.follower
    FROM Follows F1, Follows F2
    WHERE F1.followed = F2.follower
);
