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
HAVING COUNT(country) >= ALL(SELECT COUNT(country)
                            FROM X 
                            GROUP BY owner);
