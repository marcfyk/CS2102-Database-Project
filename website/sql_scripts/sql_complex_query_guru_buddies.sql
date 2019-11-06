/* Query 3: guru buddies */
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
