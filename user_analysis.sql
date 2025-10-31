WITH account_cnt_1 AS (
  SELECT
    s.date,
    sp.country,
    ac.send_interval,
    ac.is_verified,
    ac.is_unsubscribed,
    COUNT(DISTINCT ac.id) AS account_cnt,
    0 AS sent_msg,
    0 AS open_msg,
    0 AS visit_msg
  FROM `DA.account` ac
  JOIN `DA.account_session` acs ON ac.id = acs.account_id
  JOIN `DA.session_params` sp ON sp.ga_session_id = acs.ga_session_id
  JOIN `DA.session` s ON s.ga_session_id = sp.ga_session_id
  GROUP BY 1,2,3,4,5
),
email_cnt AS (
  SELECT
    DATE_ADD(s.date, INTERVAL es.sent_date  DAY) AS date,
    sp.country,
    ac.send_interval,
    ac.is_verified,
    ac.is_unsubscribed,
    0 AS account_cnt,
    COUNT(DISTINCT es.id_message) AS sent_msg,
    COUNT(DISTINCT eo.id_message) AS open_msg,
    COUNT(DISTINCT ev.id_message) AS visit_msg
  FROM `DA.email_sent` es
  LEFT JOIN `DA.email_open` eo ON es.id_message = eo.id_message
  LEFT JOIN `DA.email_visit` ev ON ev.id_message = es.id_message
  JOIN `DA.account` ac ON ac.id = es.id_account
  JOIN `DA.account_session` acs ON acs.account_id = es.id_account
  JOIN `DA.session` s ON s.ga_session_id = acs.ga_session_id
  JOIN `DA.session_params` sp ON sp.ga_session_id = acs.ga_session_id
  GROUP BY 1,2,3,4,5
),
unioncnt AS (
  SELECT * FROM account_cnt_1
  UNION ALL
  SELECT * FROM email_cnt
),
groupcnt AS (
  SELECT
    date,
    country,
    send_interval,
    is_verified,
    is_unsubscribed,
    SUM(account_cnt) AS account_cnt,
    SUM(sent_msg) AS sent_msg,
    SUM(open_msg) AS open_msg,
    SUM(visit_msg) AS visit_msg
  FROM unioncnt
  GROUP BY 1,2,3,4,5
),
with_totals AS (
  SELECT
    *,
    SUM(account_cnt) OVER (PARTITION BY country) AS total_country_account_cnt,
    SUM(sent_msg) OVER (PARTITION BY country) AS total_country_sent_cnt
  FROM groupcnt
),
ranked AS (
  SELECT
    *,
    DENSE_RANK() OVER (ORDER BY total_country_account_cnt DESC) AS rank_total_country_account_cnt,
    DENSE_RANK() OVER (ORDER BY total_country_sent_cnt DESC) AS rank_total_country_sent_cnt
  FROM with_totals
)
SELECT *
FROM ranked
WHERE rank_total_country_account_cnt <= 10 OR rank_total_country_sent_cnt <= 10;
