WITH events AS (
    SELECT id, event, url_params
    FROM stat
    WHERE 1=1
    [[AND {{period}}]]
), tagged AS (
    SELECT DISTINCT e.id, e.event, p.param AS source
    FROM events e
    CROSS JOIN LATERAL regexp_split_to_table(ltrim(coalesce(e.url_params,''),'?'), '&') AS p(param)
    WHERE split_part(p.param,'=',1) IN ('discount','utm_source','funnel','source')
      AND strpos(p.param,'=') > 0 AND split_part(p.param,'=',2) <> ''
)
SELECT source AS "Источник", event AS "Событие", count(*) AS "Количество"
FROM tagged
GROUP BY source,event
ORDER BY source,"Количество" DESC;
