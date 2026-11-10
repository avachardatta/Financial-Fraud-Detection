CREATE TABLE financial_transactions (
    step INT,
    type VARCHAR(20),
    amount NUMERIC(15, 2),
    nameOrig VARCHAR(50),
    oldbalanceOrg NUMERIC(15, 2),
    newbalanceOrig NUMERIC(15, 2),
    nameDest VARCHAR(50),
    oldbalanceDest NUMERIC(15, 2),
    newbalanceDest NUMERIC(15, 2),
    isFraud SMALLINT,
    isFlaggedFraud SMALLINT
);


-- The total number of transactions in the dataset
SELECT
	COUNT(*) 
FROM financial_transactions   --- ans 6362620



-- The total number of fraud cases

SELECT
	COUNT(*)
FROM financial_transactions
WHERE isfraud = 1;	   = 8213


-- The overall fraud percentage

WITH fraud_counts AS (
    SELECT 
        COUNT(*) AS total_tx,
        SUM(isFraud) AS total_fraud
    FROM financial_transactions
)
SELECT 
    total_tx,
    total_fraud,
    ROUND((total_fraud * 100.0) / total_tx ,2)AS fraud_percentage
FROM fraud_counts;                                    ------ 0.13 %


-- Write a query to find the total number of transactions and the total number of fraud cases grouped by the transaction


SELECT
    type,
    COUNT(*) AS total_transactions,
    SUM(isFraud) AS no_of_fraud,
    ROUND((SUM(isFraud) * 100.0) / COUNT(*),2) AS fraud_rate_percentage
FROM financial_transactions
GROUP BY type
ORDER BY no_of_fraud DESC;




-- Write a query to find the minimum, maximum, and average transaction amount for normal transactions



SELECT
	isfraud,
	MIN(amount) AS min_transaction_amt,
	MAX(amount) AS max_transaction_amt,
	ROUND(AVG(amount),2) AS avg_transaction_amt
FROM financial_transactions 
GROUP BY isfraud;




-- Write a query to find how many fraud cases (isFraud = 1) resulted in the victim's account balance being left at exactly zero 


WITH fraud_totals AS (
    SELECT 
        COUNT(*) AS total_fraud_cases,
        SUM(CASE WHEN newbalanceOrig = 0 THEN 1 ELSE 0 END) AS emptied_accounts
    FROM financial_transactions
    WHERE isFraud = 1
)
SELECT 
    total_fraud_cases,
    emptied_accounts,
    ROUND((emptied_accounts * 100.0) / total_fraud_cases, 2) AS emptied_percentage
FROM fraud_totals;


-- Write a query to find out if fraud happens more often when money is sent to a Merchant ('M%') or to another Customer ('C%').


SELECT
    CASE 
        WHEN LEFT(namedest, 1) = 'M' THEN 'Merchant'
        WHEN LEFT(namedest, 1) = 'C' THEN 'Another Customer'
        ELSE 'Unknown' 
    END AS destination_type,
    COUNT(*) AS total_transactions,
    SUM(isFraud) AS total_fraud_cases
FROM financial_transactions
GROUP BY 
    CASE 
        WHEN LEFT(namedest, 1) = 'M' THEN 'Merchant'
        WHEN LEFT(namedest, 1) = 'C' THEN 'Another Customer'
        ELSE 'Unknown' 
    END;


-- Write a query to find out how many transactions the bank's automated system flagged as fraud (isFlaggedFraud = 1).
-- Out of those flagged transactions, how many were actually fraud (isFraud = 1)?

SELECT
    COUNT(*) FILTER (WHERE isFlaggedFraud = 1) AS total_flagged_by_bank,
    COUNT(*) FILTER (WHERE isFlaggedFraud = 1 AND isFraud = 1) AS correctly_flagged_fraud,
    COUNT(*) FILTER (WHERE isFlaggedFraud = 0 AND isFraud = 1) AS missed_fraud_cases
FROM financial_transactions;



-- Write a query to find the top 5 step values (hours) with the highest number of fraud cases.
-- Include the total number of fraud cases and the total transaction amount stolen during those specific hours.



SELECT 
    step AS hour,
    COUNT(*) AS total_fraud_cases,
    SUM(amount) AS total_amount_stolen
FROM financial_transactions
WHERE isFraud = 1
GROUP BY step
ORDER BY total_fraud_cases DESC
LIMIT 5;


-- Write a query to find the top 10 largest fraudulent transactions (isFraud = 1) in the dataset.
-- Include the type, the amount stolen, the original account (nameOrig), and the destination account (nameDest).


SELECT 
    type, 
    amount, 
    nameOrig, 
    nameDest
FROM financial_transactions
WHERE isFraud = 1
ORDER BY amount DESC
LIMIT 10;
