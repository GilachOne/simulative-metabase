WITH params AS (
 SELECT coalesce([[{{company_id}}::int,]]1) AS company_id,
 coalesce([[{{date_from}}::date,]] DATE '2021-07-01') AS start_at,
 coalesce([[{{date_to}}::date + 1,]] DATE '2022-05-01') AS end_at
), cu AS (
 SELECT u.id,u.date_joined FROM users u CROSS JOIN params p WHERE u.company_id=p.company_id AND u.date_joined<p.end_at
), runs AS (
 SELECT r.* FROM coderun r JOIN cu u ON u.id=r.user_id CROSS JOIN params p WHERE r.created_at>=u.date_joined AND r.created_at<p.end_at
), submits AS (
 SELECT s.* FROM codesubmit s JOIN cu u ON u.id=s.user_id CROSS JOIN params p WHERE s.created_at>=u.date_joined AND s.created_at<p.end_at
), visits AS (
 SELECT e.* FROM userentry e JOIN cu u ON u.id=e.user_id CROSS JOIN params p WHERE e.entry_at>=u.date_joined AND e.entry_at<p.end_at
), first_success AS (
 SELECT DISTINCT ON(user_id,problem_id) user_id,problem_id,created_at AS solved_at,id AS submit_id FROM submits WHERE is_false=0 ORDER BY user_id,problem_id,created_at,id
), practice AS (
 SELECT user_id,created_at FROM runs UNION SELECT user_id,created_at FROM submits
)
, cohorts AS (SELECT id,date_trunc('month',date_joined) AS cohort FROM cu,params WHERE date_joined>=start_at), sizes AS (SELECT cohort,count(*) AS n FROM cohorts GROUP BY cohort), grid AS (SELECT c.cohort,c.n,x.k,c.cohort+x.k*interval '1 month' AS month FROM sizes c CROSS JOIN generate_series(0,9) x(k)), rates AS (SELECT g.*, CASE WHEN g.month+interval '1 month'<=p.end_at THEN round(100.0*(SELECT count(DISTINCT a.user_id) FROM practice a JOIN cohorts c ON c.id=a.user_id WHERE c.cohort=g.cohort AND a.created_at>=g.month AND a.created_at<g.month+interval '1 month')/g.n,2) END AS pct FROM grid g CROSS JOIN params p)
SELECT cohort::date AS "Когорта",n AS "Студенты",max(pct) FILTER(WHERE k=0) AS "М0, %",max(pct) FILTER(WHERE k=1) AS "М1, %",max(pct) FILTER(WHERE k=2) AS "М2, %",max(pct) FILTER(WHERE k=3) AS "М3, %",max(pct) FILTER(WHERE k=4) AS "М4, %",max(pct) FILTER(WHERE k=5) AS "М5, %",max(pct) FILTER(WHERE k=6) AS "М6, %",max(pct) FILTER(WHERE k=7) AS "М7, %",max(pct) FILTER(WHERE k=8) AS "М8, %",max(pct) FILTER(WHERE k=9) AS "М9, %" FROM rates GROUP BY cohort,n ORDER BY cohort;
