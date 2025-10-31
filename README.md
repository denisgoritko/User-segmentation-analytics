# User Segmentation & Activity Analysis (SQL)

This repository contains a single, comprehensive SQL query (`main_query.sql`) designed for a BigQuery e-commerce database. The query aggregates user account and email marketing data to enable analysis of user acquisition dynamics, email engagement, and behavioral segmentation.

## Project Goal

The primary goal is to create a unified dataset that helps analyze:
* **Account Dynamics:** When and where are accounts being created?
* **User Activity:** How are users engaging with emails (sends, opens, clicks)?
* **Behavioral Segments:** How does behavior differ based on send intervals, verification status, or subscription status?
* **Key Markets:** Which countries are most active in terms of new accounts and email engagement?

## SQL Query Logic

The query in `main_query.sql` uses multiple Common Table Expressions (CTEs) to build the final dataset logically.

1.  **`account_cnt_1` (Account Metrics):**
    * This CTE gathers metrics related to **account creation**.
    * It joins `account`, `account_session`, `session`, and `session_params` tables.
    * It counts distinct accounts (`account_cnt`) and groups them by the required dimensions: `date` (from the session, treated as creation date), `country`, `send_interval`, `is_verified`, and `is_unsubscribed`.

2.  **`email_cnt` (Email Metrics):**
    * This CTE gathers metrics related to **email activity**.
    * It joins `email_sent` with `email_open` and `email_visit` to get message-level engagement.
    * It links back to the `account` and `session` tables to get the *same dimensions* for each user (country, verification, etc.).
    * It calculates `sent_msg`, `open_msg`, and `visit_msg`.

3.  **`unioncnt` & `groupcnt` (Combining Data):**
    * The two CTEs (`account_cnt_1` and `email_cnt`) are combined using `UNION ALL`.
    * The results are then grouped by all five dimensions to create a single, aggregated row for each unique combination.

4.  **`with_totals` & `ranked` (Window Functions):**
    * **`with_totals`**: Uses `SUM(...) OVER (PARTITION BY country)` to calculate the total `account_cnt` and `sent_msg` for each country, adding these as new columns.
    * **`ranked`**: Uses `DENSE_RANK()` to rank each country based on its total accounts and total sent messages.

5.  **Final `SELECT` (Filtering):**
    * The final query selects all data from the `ranked` CTE.
    * It filters the results to show **only the Top 10 countries**, based on *either* their rank in account creation OR their rank in sent messages (`WHERE rank_... <= 10`).

## Final Dataset Schema

The query output includes the following fields:

### Dimensions
* `date`: The date of the event (account creation or email send).
* `country`: The user's country.
* `send_interval`: The user's preferred send interval.
* `is_verified`: Boolean (true/false) if the account is verified.
* `is_unsubscribed`: Boolean (true/false) if the user has unsubscribed.

### Core Metrics
* `account_cnt`: Number of accounts created.
* `sent_msg`: Number of emails sent.
* `open_msg`: Number of emails opened.
* `visit_msg`: Number of clicks (visits) from emails.

### Analytical Metrics (Window Functions)
* `total_country_account_cnt`: Total accounts ever created in that country.
* `total_country_sent_cnt`: Total emails ever sent in that country.
* `rank_total_country_account_cnt`: Rank of the country by total accounts.
* `rank_total_country_sent_cnt`: Rank of the country by total sent emails.

##  Visualization (Looker Studio)
[ View the Interactive Dashboard](https://lookerstudio.google.com/reporting/b57d352e-f879-4fe1-bfbd-8d93d63d31c0)
This dataset is used to build a dashboard in Looker Studio, which includes:
* A table/bar chart showing country-level metrics (Top 10 countries by `account_cnt`, `total_country_sent_cnt`, and their ranks).
* A time-series chart showing the dynamics of `sent_msg` over time.
