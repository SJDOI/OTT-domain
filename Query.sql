-- Q1 total no of users for liocinema and jotstar --

WITH
lsub_month AS (
  SELECT month_name, COUNT(user_id) AS lsub_count
  FROM liocinema_db.subscribers
  GROUP BY month_name
),
jsub_month AS (
  SELECT month_name, COUNT(user_id) AS jsub_count
  FROM jotstar_db.subscribers
  GROUP BY month_name
)
SELECT
  mon.month_name,
  COALESCE(jsub_month.jsub_count, 0) AS jsub_count,
  COALESCE(lsub_month.lsub_count, 0) AS lsub_count
FROM jotstar_db.dim_month_name AS mon
LEFT JOIN lsub_month ON mon.month_name = lsub_month.month_name
LEFT JOIN jsub_month ON mon.month_name = jsub_month.month_name
ORDER BY mon.month_name ASC;

-- Q2 What is total no of contents available on jiocinema and lotstar? How do the differ in terms of content type and language? --
-- Jotstar_contents --
SELECT COUNT(DISTINCT content_id) AS no_of_contents,
       language,
       content_type
FROM jotstar_db.contents
GROUP BY language, content_type
ORDER BY no_of_contents DESC;

-- liocinema_contents --
SELECT COUNT(DISTINCT content_id) AS no_of_contents,
       language,
       content_type
FROM liocinema_db.contents
GROUP BY language, content_type
ORDER BY no_of_contents DESC;

-- Q3 What is the distribution of user by age, city-tier, subscription_plan for each platform? --

-- jotstar --
SELECT COUNT(user_id) AS total_users,
       age_group,
       city_tier,
       subscription_plan
FROM jotstar_db.subscribers
GROUP BY age_group, city_tier, subscription_plan
ORDER BY total_users DESC;

-- liocinema --
SELECT COUNT(user_id) AS total_users,
       age_group,
       city_tier,
       subscription_plan
FROM liocinema_db.subscribers
GROUP BY age_group, city_tier, subscription_plan
ORDER BY total_users DESC;

-- Q4 What perentage of jotstar and liocinema users active and inactive? How do thses rates very by age group and subcription plan? --
 -- jotstar --
SELECT
    age_group,
    subscription_plan,
    ROUND(CAST(COUNT(CASE WHEN last_active_date IS NULL THEN 1 ELSE NULL END) AS REAL) * 100.0 / COUNT(*), 2) AS active_users_percent
FROM jotstar_db.subscribers
GROUP BY age_group, subscription_plan;

 -- liocinema --
SELECT
    age_group,
    subscription_plan,
    ROUND(CAST(COUNT(CASE WHEN last_active_date IS NULL THEN 1 ELSE NULL END) AS REAL) * 100.0 / COUNT(*), 2) AS active_users_percent
FROM liocinema_db.subscribers
GROUP BY age_group, subscription_plan;

-- Q5 What is the average watch time of joistar and liocinema during the analysis period? How do these compare bi city-tier and device type?--
-- jotstar --  
   SELECT ROUND(AVG(total_watch_time_mins), 2) AS Avg_watch_time,
          city_tier,
          device_type
   FROM jotstar_db.content_consumption AS cc
   JOIN jotstar_db.subscribers AS sub
     ON cc.user_id = sub.user_id
   GROUP BY city_tier, device_type;
   
-- liocinema --
   SELECT ROUND(AVG(total_watch_time_mins), 2) AS Avg_watch_time,
          city_tier,
          device_type
   FROM liocinema_db.content_consumption AS cc
   JOIN liocinema_db.subscribers AS sub
     ON cc.user_id = sub.user_id
   GROUP BY city_tier, device_type;
   
-- Q6 How do inactivity pattern  correleate with avg watch time ? Are less engaged users more likely to become inactive ?
-- jotstar --
USE jotstar_db;

WITH s_binary_activity AS (
    SELECT
        user_id,
        CASE
            WHEN last_active_date IS NULL THEN 1
            ELSE 0
        END AS b_activity
    FROM
        subscribers
),
calculations AS (
    SELECT
        -- Numerator --
        (COUNT(*) * SUM(s_bin.b_activity * cc.total_watch_time_mins) - SUM(s_bin.b_activity) * SUM(cc.total_watch_time_mins)) AS numerator,
        -- Denominator (fixed parentheses) --
        SQRT(
            (COUNT(*) * SUM(s_bin.b_activity * s_bin.b_activity) - POW(SUM(s_bin.b_activity), 2)) *
            (COUNT(*) * SUM(cc.total_watch_time_mins * cc.total_watch_time_mins) - POW(SUM(cc.total_watch_time_mins), 2))
        ) AS denominator
    FROM
        content_consumption AS cc
    JOIN
        s_binary_activity AS s_bin ON cc.user_id = s_bin.user_id
)
-- Final calculation --
SELECT
    ROUND(numerator / NULLIF(denominator, 0), 2) AS correlation_btw_watchtime_and_engagement 
FROM
    calculations;  
-- liocinema --
USE liocinema_db;

WITH s_binary_activity AS (
    SELECT
        user_id,
        CASE
            WHEN last_active_date IS NULL THEN 1
            ELSE 0
        END AS b_activity
    FROM
        subscribers
),
calculations AS (
    SELECT
        -- Numerator --
        (COUNT(*) * SUM(s_bin.b_activity * cc.total_watch_time_mins) - SUM(s_bin.b_activity) * SUM(cc.total_watch_time_mins)) AS numerator,
        -- Denominator (fixed parentheses) --
        SQRT(
            (COUNT(*) * SUM(s_bin.b_activity * s_bin.b_activity) - POW(SUM(s_bin.b_activity), 2)) *
            (COUNT(*) * SUM(cc.total_watch_time_mins * cc.total_watch_time_mins) - POW(SUM(cc.total_watch_time_mins), 2))
        ) AS denominator
    FROM
        content_consumption AS cc
    JOIN
        s_binary_activity AS s_bin ON cc.user_id = s_bin.user_id
)
-- Final calculation --
SELECT
    ROUND(numerator / NULLIF(denominator, 0), 2) AS correlation_btw_watchtime_and_engagement 
FROM
    calculations; 
    
