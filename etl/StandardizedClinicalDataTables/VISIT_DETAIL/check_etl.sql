
-- -----------------------------------------------------------------------------
-- File created - January-9-2018
-- ----------------------------------------------------------------------------

-- --------------------------------------------------
-- Need to install pgTAP
-- http://pgtap.org/
-- --------------------------------------------------


BEGIN;

SELECT plan( 7 );

SELECT results_eq
(
'
SELECT hadm_id, count(1) as total
from omop.visit_detail v
JOIN admissions a ON v.visit_occurrence_id = a.mimic_id
WHERE v.visit_detail_type_concept_id = 4079617
GROUP BY 1
ORDER BY 2 DESC, 1;
'
,
'
WITH tmp as
(
        SELECT hadm_id, count(1) counter
        from transfers
        where eventtype is distinct from ''discharge''
        group by 1 order by 2 desc
),
minus_bed_changement as
(
        SELECT hadm_id, count(*) nb_minus
        FROM transfers
        WHERE prev_wardid = curr_wardid
        group by hadm_id
)
SELECT hadm_id,
   case when nb_minus is null then counter else counter - nb_minus end as total
FROM tmp
LEFT JOIN minus_bed_changement USING (hadm_id)
ORDER BY 2 desc, 1;
'
,
'VISIT_DETAIL -- test same number transfers'
);



SELECT results_eq
(
'
SELECT count(visit_detail_source_concept_id)
FROM omop.visit_detail
GROUP BY visit_detail_source_concept_id
ORDER BY 1 DESC;
'
,
'
SELECT count(visit_detail_source_value)
FROM omop.visit_detail
GROUP BY visit_detail_source_value
ORDER BY 1 DESC;
'
,
'VISIT_DETAIL -- test visit_detail_source_value and visit_detail_source_concept_id match'
);



SELECT results_eq
(
'
SELECT COUNT(admitted_from_source_concept_id)
FROM omop.visit_detail
GROUP BY admitted_from_source_concept_id
ORDER BY 1 DESC;
'
,
'
SELECT COUNT(admitted_from_source_value)
FROM omop.visit_detail
GROUP BY admitted_from_source_value
ORDER BY 1 DESC;
'
,
'VISIT_DETAIL -- test admitted_from_source_concept_id and admitted_from_source_value match'
);



SELECT results_eq
(
'
SELECT COUNT(distinct person_id)
  , COUNT(distinct visit_occurrence_id)
FROM omop.visit_detail
WHERE visit_detail_concept_id = 581382
AND visit_detail_type_concept_id = 2000000006;
'
,
'
SELECT COUNT(distinct subject_id)
  , COUNT(distinct hadm_id)
FROM icustays;
'
,
'VISIT_DETAIL -- test patients number in visit_detail/icustays'
);



SELECT results_eq
(
'
WITH tmp AS
(
  SELECT visit_detail_id, visit_occurrence_id
  , CASE
      WHEN visit_detail_end_datetime < visit_detail_start_datetime
      THEN 1
    ELSE 0 END AS abnormal
  FROM omop.visit_detail
)
SELECT sum(abnormal) FROM tmp;
'
,
'
select 0::integer;
'
,
'VISIT_DETAIL -- check start_datetime < end_datetime'
);



SELECT results_eq
(
'
WITH tmp AS
(
  SELECT visit_detail_id, visit_occurrence_id
    , CASE
        WHEN visit_detail_end_date < visit_detail_start_date
        THEN 1
        ELSE 0
      END AS abnormal
  FROM omop.visit_detail
)
SELECT sum(abnormal) FROM tmp;
'
,
'
select 0::integer;
'
,
'VISIT_DETAIL -- check start_date < end_date'
);

select results_eq
(
'
SELECT COUNT(*)::INTEGER AS res
FROM omop.visit_detail
WHERE care_site_id IS NULL;
'
,
'
SELECT 0::INTEGER AS res;
'
,
'VISIT_DETAIL -- check care site is never null'
);

SELECT * FROM finish();
ROLLBACK;
