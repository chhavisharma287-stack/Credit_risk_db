
-- STEP 1: PREVIEW DATA
SELECT * FROM credit_data LIMIT 10;  -- See the first 10 rows to confirm import success

-- STEP 2: CHECK DATA SIZE
SELECT COUNT(*) AS total_records FROM credit_data;  -- Check how many records are in the dataset

-- STEP 3: CHECK FOR MISSING VALUES
SELECT 
    SUM(CASE WHEN person_age IS NULL THEN 1 ELSE 0 END) AS missing_age,
    SUM(CASE WHEN person_income IS NULL THEN 1 ELSE 0 END) AS missing_income,
    SUM(CASE WHEN loan_amnt IS NULL THEN 1 ELSE 0 END) AS missing_loan_amount,
    SUM(CASE WHEN loan_status IS NULL THEN 1 ELSE 0 END) AS missing_loan_status
FROM credit_data;  -- Count missing values in key columns

-- STEP 4: CHECK FOR DUPLICATES
SELECT 
    person_age, person_income, loan_amnt, COUNT(*) 
FROM credit_data
GROUP BY person_age, person_income, loan_amnt
HAVING COUNT(*) > 1;  -- Identify duplicate rows if any

-- STEP 5: DATA STANDARDIZATION (OPTIONAL)
UPDATE credit_data
SET person_home_ownership = INITCAP(person_home_ownership);  -- Standardize text case (e.g., "OWN" → "Own")

-- STEP 6: BASIC STATISTICAL SUMMARY
SELECT 
    ROUND(AVG(person_age),2) AS avg_age,
    ROUND(AVG(person_income),2) AS avg_income,
    ROUND(AVG(loan_amnt),2) AS avg_loan_amount,
    ROUND(AVG(loan_int_rate),2) AS avg_interest_rate
FROM credit_data;  -- Basic descriptive stats of numeric columns


--- STEP 7: DEFAULT RATE BY LOAN INTENT
SELECT 
    loan_intent,
    ROUND(AVG(loan_status)*100,2) AS default_rate
FROM credit_data
GROUP BY loan_intent
ORDER BY default_rate DESC;  -- Shows which loan purposes have higher default risk

-- STEP 8: DELINQUENCY RATIO BY LOAN GRADE

SELECT 
    loan_grade,
    ROUND(SUM(CASE WHEN loan_status = 1 THEN 1 ELSE 0 END)*100.0 / COUNT(*), 2) AS delinquency_ratio
FROM credit_data
GROUP BY loan_grade
ORDER BY delinquency_ratio DESC;  -- Measures % of defaulters by credit grade

-- STEP 9: LOSS RATE BY LOAN GRADE
SELECT 
    loan_grade,
    ROUND(SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END) / SUM(loan_amnt) * 100, 2) AS loss_rate
FROM credit_data
GROUP BY loan_grade
ORDER BY loss_rate DESC;  -- Losses as % of total loan amount per grade


-- STEP 10: RISK SEGMENTATION BY CREDIT HISTORY LENGTH
SELECT 
    CASE 
        WHEN cb_person_cred_hist_length < 2 THEN 'High Risk'
        WHEN cb_person_cred_hist_length BETWEEN 2 AND 5 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_category,
    ROUND(AVG(loan_status)*100,2) AS default_rate
FROM credit_data
GROUP BY risk_category
ORDER BY default_rate DESC;  -- Uses credit history as proxy for risk

-- STEP 11: DEBT-TO-INCOME RATIO

SELECT 
    person_income,
    loan_amnt,
    ROUND(loan_amnt / NULLIF(person_income, 0), 2) AS debt_to_income_ratio
FROM credit_data
LIMIT 10;  -- Calculates DTI for first 10 customers (replace LIMIT 10 to see more)

-- STEP 12: COMBINED CREDIT RISK SUMMARY (FOR POWER BI)

CREATE OR REPLACE VIEW credit_risk_summary AS
SELECT 
    loan_intent,
    loan_grade,
    ROUND(SUM(CASE WHEN loan_status = 1 THEN 1 ELSE 0 END)*100.0 / COUNT(*), 2) AS delinquency_ratio,
    ROUND(SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END) / SUM(loan_amnt) * 100, 2) AS loss_rate,
    ROUND(AVG(loan_amnt),2) AS avg_loan_amount,
    ROUND(AVG(person_income),2) AS avg_income,
    ROUND(AVG(loan_int_rate),2) AS avg_interest_rate
FROM credit_data
GROUP BY loan_intent, loan_grade
ORDER BY delinquency_ratio DESC;  -- Creates summary view for easy dashboard connection


-- STEP 13: VERIFY THE VIEW
SELECT * FROM credit_risk_summary LIMIT 10;  -- Check summarized results (you’ll use this in Power BI)
