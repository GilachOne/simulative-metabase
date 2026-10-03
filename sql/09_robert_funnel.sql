WITH history AS (
 SELECT *, count(nullif(url_params,'')) OVER (PARTITION BY uid ORDER BY created_at,id) AS source_group FROM stat
), attributed AS (
 SELECT id,created_at,event,uid,
 CASE WHEN uid IS NULL THEN coalesce(url_params,'') ELSE
 coalesce(max(nullif(url_params,'')) OVER (PARTITION BY uid,source_group),'') END AS attribution_params
 FROM history
), selected AS (
 SELECT * FROM attributed WHERE 1=1
 [[AND {{period}}]]
 [[AND EXISTS (SELECT 1 FROM regexp_split_to_table(ltrim(attribution_params,'?'),'&') p(param) WHERE p.param={{source}} AND split_part(p.param,'=',1) IN ('discount','utm_source','funnel','source'))]]
), steps(ord,event,label) AS (
 VALUES (1,'enter_site','1. Зашёл на сайт'),(2,'open_page','2. Открыл страницу'),
 (3,'request_consultation','3. Заявка на консультацию'),(4,'request_demo','4. Запросил демо'),
 (5,'go_to_payment','5. Перешёл к оплате'),(6,'get_test_results','6. Запросил результаты теста')
)
SELECT steps.label AS "Событие", count(s.id) AS "Количество событий"
FROM steps LEFT JOIN selected s ON s.event=steps.event
GROUP BY steps.ord,steps.label ORDER BY steps.ord;
