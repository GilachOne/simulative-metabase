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

SELECT count(DISTINCT user_id) AS "Студенты с новым решением" FROM first_success, params WHERE solved_at >= start_at;
