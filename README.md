# SQL Portfolio Project: Financial Fraud Detection & System Risk Analysis

##  Project Overview
In the modern banking sector, identifying fraudulent activity quickly while minimizing disruptions to legitimate users is a critical challenge. This project conducts a deep-dive forensic audit of a synthetic financial dataset containing **6.3 million rows** of transaction logs. By simulating the role of a Lead Fraud Analyst, this project uncovers distinct criminal patterns, evaluates structural system risks, and assesses the effectiveness of automated banking security triggers using advanced relational database querying techniques.

---

##  Project Objectives
* **Quantify Core Risk Exposure:** Establish baseline benchmarks for total fraud volume, overall financial impact, and transaction distribution.
* **Isolate Criminal Mechanics:** Uncover the specific transaction types, behavioral methodologies (e.g., account-draining strategies), and destination preferences used by malicious actors.
* **Audit Automated Defenses:** Measure the performance, accuracy, and failure rate of the bank's internal rule-based flagging systems (`isFlaggedFraud`).
* **Identify Temporal Attack Vectors:** Detect high-risk operational windows by analyzing hourly transaction volumes to map out coordinated fraud waves.

---

##  Project Structure & Forensic Insights

###  Phase 1: The Initial Forensic Audit
This phase establishes our data baselines to understand the scope of fraudulent activity moving through the bank's network.

```sql
-- Query 1: Calculating overall baseline fraud metrics
SELECT 
    COUNT(*) AS total_transactions,
    SUM(isFraud) AS total_fraud_cases,
    ROUND((SUM(isFraud) * 100.0) / COUNT(*), 2) AS fraud_percentage
FROM financial_transactions;

-- Query 2: Mapping fraud across transaction channels
SELECT
    type,
    COUNT(*) AS total_transactions,
    SUM(isFraud) AS no_of_fraud,
    ROUND((SUM(isFraud) * 100.0) / COUNT(*), 2) AS fraud_rate_percentage
FROM financial_transactions
GROUP BY type
ORDER BY no_of_fraud DESC;
Key Insight: Out of 6,362,620 network actions, 8,213 transactions were confirmed fraud, establishing a baseline fraud rate of 0.13%.

Key Insight: Criminal activity is completely absent from standard consumer actions like PAYMENT, CASH_IN, or DEBIT. Instead, fraud is strictly isolated to TRANSFER and CASH_OUT loops, revealing the specific channels security teams must monitor.

 Phase 2: High-Value Financial Anomalies
Here, we analyze the financial volume of the attacks and look closely at the "Vault Emptying" behavior.

SQL
-- Query 3: Comparing volume ranges between normal traffic and fraud
SELECT
    isFraud,
    COUNT(*) AS total_transactions,
    MIN(amount) AS min_transaction_amt,
    MAX(amount) AS max_transaction_amt,
    AVG(amount) AS avg_transaction_amt
FROM financial_transactions 
GROUP BY isFraud;

-- Query 4: Identifying the "Emptying the Vault" pattern
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
Key Insight: Fraudulent transactions carry a drastically higher average amount compared to normal transactions, showing that actors prioritize high-impact strikes over low-value retail noise.

Key Insight: The investigation confirmed a definitive behavioral signature: in a massive majority of verified fraud cases, the victim's account balance is left at exactly 0, proving that automated scripts are rapidly clearing out balances entirely.

 Phase 3: Identity & Destination Tracking
This phase profiles who is receiving the stolen capital and audits how well the bank's active rules are performing.

SQL
-- Query 5: Profiling the recipient account types (Customer vs. Merchant)
SELECT
    CASE 
        WHEN LEFT(namedest, 1) = 'M' THEN 'Merchant'
        WHEN LEFT(namedest, 1) = 'C' THEN 'Another Customer'
        ELSE 'Unknown' 
    END AS destination_type,
    COUNT(*) AS total_transactions,
    SUM(isFraud) AS total_fraud_cases
FROM financial_transactions
GROUP BY 1;

-- Query 6: Auditing the bank's internal alert system accuracy (Using Advanced FILTER Syntax)
SELECT
    COUNT(*) FILTER (WHERE isFlaggedFraud = 1) AS total_flagged_by_bank,
    COUNT(*) FILTER (WHERE isFlaggedFraud = 1 AND isFraud = 1) AS correctly_flagged_fraud,
    COUNT(*) FILTER (WHERE isFlaggedFraud = 0 AND isFraud = 1) AS missed_fraud_cases
FROM financial_transactions;
Key Insight: 100% of fraud routing targets individual customer accounts (C%), evading retail merchant accounts (M%) completely. This implies illicit capital is being pushed straight into external mule accounts.

Key Insight: The current infrastructure audit revealed an alarming systemic gap. The existing automated threshold rule (isFlaggedFraud = 1) failed to catch a massive percentage of verified fraud, showing that static regulatory flags are completely inadequate against modern, dynamic attacks.

 Phase 4: Behavioral Timings & Peak Losses
The final phase exposes the specific hours these attacks peak and extracts the single largest hits to map severe financial exposures.

SQL
-- Query 7: Isolating high-risk operational windows
SELECT 
    step AS hour,
    COUNT(*) AS total_fraud_cases,
    SUM(amount) AS total_amount_stolen
FROM financial_transactions
WHERE isFraud = 1
GROUP BY step
ORDER BY total_fraud_cases DESC
LIMIT 5;

-- Query 8: Documenting the multi-million dollar heists
SELECT 
    type, 
    amount, 
    nameOrig, 
    nameDest
FROM financial_transactions
WHERE isFraud = 1
ORDER BY amount DESC
LIMIT 10;
Key Insight: Fraud cases spike heavily in compressed, specific hourly sequences (step), indicating highly coordinated, automated script attacks designed to sweep balances bare before human oversight can intervene.

Key Insight: The top 10 single largest fraud losses all maximize out at massive, multi-million dollar limits, pointing directly to organized asset extraction targeting high-net-worth accounts.

 System-Generated Reports
To translate these raw SQL insights into operational tools for the bank's fraud department, the following reports are generated programmatically from the database to assist security teams:

1. Daily High-Risk Threat Assessment Report
Target Audience: Fraud Investigation Unit & Operations Managers.

Purpose: Triggers a real-time operational workflow by generating a daily list of high-value TRANSFER and CASH_OUT events where the originating account was entirely cleared out (newbalanceOrig = 0). This report isolates the highest probability fraud alerts for human analysts to review first.

2. System Defense Performance Matrix (KPI Dashboard)
Target Audience: Risk Compliance Officers & Chief Security Officer (CSO).

Purpose: A monthly report tracking the performance metrics of the automated detection system. It reports the False Negative Rate (how much actual fraud the automated system missed) to justify updating rules and investing in machine-learning-based detection patterns.

3. Chronological Attack-Pattern Report
Target Audience: Security Infrastructure & Database Administrators.

Purpose: Maps out the exact hours (steps) experiencing anomalous surges in volume. This report allows network teams to scale server resources during high-risk script-attack windows and deploy tougher step-up authentication checks during these hours.

 Technical Reflection & Future Scope
Project Design: Single-Table Architecture
For this phase of the analysis, the entire dataset was maintained as a single, flat table (financial_transactions).

The Benefit: Keeping the data in a flat structure allowed for rapid data exploration, straightforward query writing, and high-speed execution of conditional aggregations (like the FILTER clauses) without the overhead of complex JOIN operations across millions of rows
