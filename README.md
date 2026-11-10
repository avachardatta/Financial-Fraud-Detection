# Financial Fraud Analysis: Where Fraud Happens and What the Bank Misses

PostgreSQL analysis of 6.36 million mobile-money transactions (PaySim synthetic dataset), written for the bank's Head of Fraud Risk.

## 1. Business problem

**Who is asking:** the Head of Fraud Risk.

**Problem statement:** fraud cost the bank 12.06 billion over the period (8,213 fraud cases), and the current automatic alert rule is suspected to miss most of it. The Head of Fraud Risk must decide where to focus monitoring and whether to replace the alert rule. Using 6.36M transactions (type, amount, balances before and after, sender, receiver, fraud labels), find which transactions carry the fraud, what fraud looks like, and how much the current rule catches, so the team can build better alert rules.

**Questions answered:**
1. How common is fraud, and how much money is lost?
2. Which transaction types carry the fraud?
3. How do fraud amounts and balances differ from normal transactions?
4. How much fraud does the bank's current alert rule (`isFlaggedFraud`) catch?

## 2. Data

PaySim synthetic mobile-money dataset (public, Kaggle). One table, `financial_transactions`, 6,362,620 rows. Amounts are in the dataset's local currency units (no currency stated).

| Column | Meaning |
| --- | --- |
| step | hour of the simulation (1 step = 1 hour, 30 days) |
| type | CASH_IN, CASH_OUT, DEBIT, PAYMENT, TRANSFER |
| amount | transaction amount |
| nameOrig / nameDest | sender / receiver account (C = customer, M = merchant) |
| oldbalanceOrg / newbalanceOrig | sender balance before / after |
| oldbalanceDest / newbalanceDest | receiver balance before / after |
| isFraud | 1 = confirmed fraud |
| isFlaggedFraud | 1 = flagged by the bank's current rule (transfers over 200,000) |

## 3. How I worked (7 steps)

1. **Define:** problem statement and questions above.
2. **Collect:** created the table and loaded the 6.36M-row CSV into PostgreSQL.
3. **Clean:** checked row counts, data types and label values (isFraud, isFlaggedFraud are 0/1).
4. **Explore:** counts and amounts by type and by fraud label.
5. **Analyze:** SQL with GROUP BY, CASE, CTEs, `COUNT(*) FILTER`, and ranking (top hours, largest frauds).
6. **Visualize:** result tables below.
7. **Communicate:** insights and recommendations below.

## 4. Key numbers

| Metric | Value |
| --- | --- |
| Transactions | 6,362,620 |
| Fraud cases | 8,213 (**0.13%**) |
| Money lost to fraud | **12.06 billion** |
| Average fraud amount | 1,467,967 (**8x** the normal average of 178,197) |
| Fraud that emptied the sender's account | 8,053 of 8,213 (**98.1%**) |
| Fraud caught by the current rule | **16 of 8,213 (0.2%)** |

**Fraud by transaction type**

| Type | Transactions | Fraud cases | Fraud rate |
| --- | --- | --- | --- |
| CASH_OUT | 2,237,500 | 4,116 | 0.18% |
| TRANSFER | 532,909 | 4,097 | **0.77%** |
| PAYMENT | 2,151,495 | 0 | 0% |
| CASH_IN | 1,399,284 | 0 | 0% |
| DEBIT | 41,432 | 0 | 0% |

## 5. Insights

1. **All fraud sits in two types.** TRANSFER and CASH_OUT carry 100% of fraud cases while being 44% of transactions. PAYMENT, CASH_IN and DEBIT have zero fraud.
2. **TRANSFER is the riskiest.** Its fraud rate (0.77%) is 4x CASH_OUT (0.18%). Fraud cases are split almost evenly (4,097 vs 4,116), which fits a pattern of moving money out (TRANSFER), then withdrawing it (CASH_OUT).
3. **Fraud empties accounts.** 98.1% of fraud transactions leave the sender's balance at exactly 0, and the average fraud is 8x larger than a normal transaction. The largest fraud amounts stop at exactly 10,000,000, which looks like a per-transaction limit.
4. **The current alert rule almost never fires.** It flagged only 16 transactions. All 16 were fraud (no false alarms), but it **missed 8,197 cases (99.8%)**.

## 6. Recommendations

| Action | Why (the number) | What to watch |
| --- | --- | --- |
| Focus monitoring on TRANSFER and CASH_OUT only | 100% of fraud, 44% of transactions | alerts per day and fraud caught in these types |
| Add an alert: TRANSFER or CASH_OUT that leaves the sender balance at 0 | 98.1% of frauds do this | share of fraud caught, false alarm rate |
| Review a TRANSFER followed soon by a CASH_OUT of a similar amount | fraud splits almost evenly between the two | number of linked pairs found |
| Replace or widen the current rule | it catches 0.2% of fraud | fraud caught vs alerts raised, monthly |

## 7. Executive summary

Fraud is rare (0.13%) but expensive (12.06 billion), and all of it is in TRANSFER and CASH_OUT. The bank's current rule catches only 16 of 8,213 frauds. **Recommendation:** add a rule that flags TRANSFER/CASH_OUT transactions that empty the sender's account, which covers 98% of fraud, and test its false-alarm rate before rollout.

## 8. Files

```
financial_transactions_fraud_detection_project.sql   # table creation + all analysis queries
```

The 6.36M-row CSV is not in the repo (too large); download PaySim from Kaggle and load it into the `financial_transactions` table.

## 9. Limitations and next steps

- The data is synthetic (simulated), so patterns are realistic but not from a real bank.
- A "balance goes to 0" rule will also flag some honest customers; its false-alarm rate needs testing on normal transactions before use.
- One flat table was enough for this analysis; joins were not needed.
- Next: measure the false-alarm rate of the new rule, and analyze fraud by hour (`step`) to find peak attack times.

**Tools:** PostgreSQL (GROUP BY, CASE, CTEs, FILTER, ORDER BY / LIMIT).
