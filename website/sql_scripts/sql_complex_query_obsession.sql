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
