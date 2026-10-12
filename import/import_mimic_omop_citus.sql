-- Loads the MIMIC-OMOP export (etl/Result) into a single-node Citus database.
-- Run from the export folder: psql -v shard_count=<cpu cores> -f import_mimic_omop_citus.sql

\set ON_ERROR_STOP true

CREATE EXTENSION IF NOT EXISTS citus;
drop schema if exists omop cascade;
create schema omop;
set search_path to omop;
\i 'OMOPCDM_postgresql_5.4_ddl.sql'
\i 'mimic-omop-alter.sql'
\i 'mimic-omop-citus.sql'

-- Row (heap) tables

\copy omop.concept FROM PROGRAM 'gzip -dc concept.csv.gz' CSV HEADER NULL '' QUOTE '"';
\copy omop.concept_ancestor FROM PROGRAM 'gzip -dc concept_ancestor.csv.gz' CSV HEADER NULL '' QUOTE '"';
\copy omop.concept_class FROM PROGRAM 'gzip -dc concept_class.csv.gz' CSV HEADER NULL '' QUOTE '"';
\copy omop.concept_relationship FROM PROGRAM 'gzip -dc concept_relationship.csv.gz' CSV HEADER NULL '' QUOTE '"';
\copy omop.concept_synonym FROM PROGRAM 'gzip -dc concept_synonym.csv.gz' CSV HEADER NULL '' QUOTE '"';
\copy omop.domain FROM PROGRAM 'gzip -dc domain.csv.gz' CSV HEADER NULL '' QUOTE '"';
\copy omop.drug_strength FROM PROGRAM 'gzip -dc drug_strength.csv.gz' CSV HEADER NULL '' QUOTE '"';
\copy omop.relationship FROM PROGRAM 'gzip -dc relationship.csv.gz' CSV HEADER NULL '' QUOTE '"';
\copy omop.source_to_concept_map FROM PROGRAM 'gzip -dc source_to_concept_map.csv.gz' CSV HEADER NULL '' QUOTE '"';
\copy omop.vocabulary FROM PROGRAM 'gzip -dc vocabulary.csv.gz' CSV HEADER NULL '' QUOTE '"';
\copy omop.attribute_definition FROM PROGRAM 'gzip -dc attribute_definition.csv.gz' CSV HEADER NULL '' QUOTE '"';
\copy omop.care_site FROM PROGRAM 'gzip -dc care_site.csv.gz' CSV HEADER NULL '' QUOTE '"';
\copy omop.cdm_source FROM PROGRAM 'gzip -dc cdm_source.csv.gz' CSV HEADER NULL '' QUOTE '"';
\copy omop.cohort FROM PROGRAM 'gzip -dc cohort.csv.gz' CSV HEADER NULL '' QUOTE '"';
\copy omop.cohort_attribute FROM PROGRAM 'gzip -dc cohort_attribute.csv.gz' CSV HEADER NULL '' QUOTE '"';
\copy omop.cohort_definition FROM PROGRAM 'gzip -dc cohort_definition.csv.gz' CSV HEADER NULL '' QUOTE '"';
\copy omop.cost FROM PROGRAM 'gzip -dc cost.csv.gz' CSV HEADER NULL '' QUOTE '"';
\copy omop.episode_event FROM PROGRAM 'gzip -dc episode_event.csv.gz' CSV HEADER NULL '' QUOTE '"';
\copy omop.fact_relationship FROM PROGRAM 'gzip -dc fact_relationship.csv.gz' CSV HEADER NULL '' QUOTE '"';
\copy omop.location FROM PROGRAM 'gzip -dc location.csv.gz' CSV HEADER NULL '' QUOTE '"';
\copy omop.note FROM PROGRAM 'gzip -dc note.csv.gz' CSV HEADER NULL '' QUOTE '"';
\copy omop.person FROM PROGRAM 'gzip -dc person.csv.gz' CSV HEADER NULL '' QUOTE '"';
\copy omop.provider FROM PROGRAM 'gzip -dc provider.csv.gz' CSV HEADER NULL '' QUOTE '"';

\i 'OMOPCDM_postgresql_5.4_indices_vocabulary.sql'

-- Columnar tables are loaded sorted: columnar keeps min/max per chunk of rows and skips
-- the chunks a filter excludes, which only pays off when the filtered columns are clustered.

CREATE TEMP TABLE stage_observation_period (LIKE omop.observation_period);
\copy stage_observation_period FROM PROGRAM 'gzip -dc observation_period.csv.gz' CSV HEADER NULL '' QUOTE '"';
INSERT INTO omop.observation_period SELECT * FROM stage_observation_period ORDER BY person_id, observation_period_start_date;
DROP TABLE stage_observation_period;

CREATE TEMP TABLE stage_visit_occurrence (LIKE omop.visit_occurrence);
\copy stage_visit_occurrence FROM PROGRAM 'gzip -dc visit_occurrence.csv.gz' CSV HEADER NULL '' QUOTE '"';
INSERT INTO omop.visit_occurrence SELECT * FROM stage_visit_occurrence ORDER BY visit_concept_id, person_id, visit_start_date;
DROP TABLE stage_visit_occurrence;

CREATE TEMP TABLE stage_visit_detail (LIKE omop.visit_detail);
\copy stage_visit_detail FROM PROGRAM 'gzip -dc visit_detail.csv.gz' CSV HEADER NULL '' QUOTE '"';
INSERT INTO omop.visit_detail SELECT * FROM stage_visit_detail ORDER BY visit_detail_concept_id, person_id, visit_detail_start_date;
DROP TABLE stage_visit_detail;

CREATE TEMP TABLE stage_condition_occurrence (LIKE omop.condition_occurrence);
\copy stage_condition_occurrence FROM PROGRAM 'gzip -dc condition_occurrence.csv.gz' CSV HEADER NULL '' QUOTE '"';
INSERT INTO omop.condition_occurrence SELECT * FROM stage_condition_occurrence ORDER BY condition_concept_id, person_id, condition_start_date;
DROP TABLE stage_condition_occurrence;

CREATE TEMP TABLE stage_drug_exposure (LIKE omop.drug_exposure);
\copy stage_drug_exposure FROM PROGRAM 'gzip -dc drug_exposure.csv.gz' CSV HEADER NULL '' QUOTE '"';
INSERT INTO omop.drug_exposure SELECT * FROM stage_drug_exposure ORDER BY drug_concept_id, person_id, drug_exposure_start_date;
DROP TABLE stage_drug_exposure;

CREATE TEMP TABLE stage_procedure_occurrence (LIKE omop.procedure_occurrence);
\copy stage_procedure_occurrence FROM PROGRAM 'gzip -dc procedure_occurrence.csv.gz' CSV HEADER NULL '' QUOTE '"';
INSERT INTO omop.procedure_occurrence SELECT * FROM stage_procedure_occurrence ORDER BY procedure_concept_id, person_id, procedure_date;
DROP TABLE stage_procedure_occurrence;

CREATE TEMP TABLE stage_device_exposure (LIKE omop.device_exposure);
\copy stage_device_exposure FROM PROGRAM 'gzip -dc device_exposure.csv.gz' CSV HEADER NULL '' QUOTE '"';
INSERT INTO omop.device_exposure SELECT * FROM stage_device_exposure ORDER BY device_concept_id, person_id, device_exposure_start_date;
DROP TABLE stage_device_exposure;

CREATE TEMP TABLE stage_measurement (LIKE omop.measurement);
\copy stage_measurement FROM PROGRAM 'gzip -dc measurement.csv.gz' CSV HEADER NULL '' QUOTE '"';
INSERT INTO omop.measurement SELECT * FROM stage_measurement ORDER BY measurement_concept_id, person_id, measurement_date;
DROP TABLE stage_measurement;

CREATE TEMP TABLE stage_observation (LIKE omop.observation);
\copy stage_observation FROM PROGRAM 'gzip -dc observation.csv.gz' CSV HEADER NULL '' QUOTE '"';
INSERT INTO omop.observation SELECT * FROM stage_observation ORDER BY observation_concept_id, person_id, observation_date;
DROP TABLE stage_observation;

CREATE TEMP TABLE stage_death (LIKE omop.death);
\copy stage_death FROM PROGRAM 'gzip -dc death.csv.gz' CSV HEADER NULL '' QUOTE '"';
INSERT INTO omop.death SELECT * FROM stage_death ORDER BY person_id;
DROP TABLE stage_death;

CREATE TEMP TABLE stage_note_nlp (LIKE omop.note_nlp);
\copy stage_note_nlp FROM PROGRAM 'gzip -dc note_nlp.csv.gz' CSV HEADER NULL '' QUOTE '"';
INSERT INTO omop.note_nlp SELECT * FROM stage_note_nlp ORDER BY note_nlp_concept_id, note_id;
DROP TABLE stage_note_nlp;

CREATE TEMP TABLE stage_specimen (LIKE omop.specimen);
\copy stage_specimen FROM PROGRAM 'gzip -dc specimen.csv.gz' CSV HEADER NULL '' QUOTE '"';
INSERT INTO omop.specimen SELECT * FROM stage_specimen ORDER BY specimen_concept_id, person_id, specimen_date;
DROP TABLE stage_specimen;

CREATE TEMP TABLE stage_payer_plan_period (LIKE omop.payer_plan_period);
\copy stage_payer_plan_period FROM PROGRAM 'gzip -dc payer_plan_period.csv.gz' CSV HEADER NULL '' QUOTE '"';
INSERT INTO omop.payer_plan_period SELECT * FROM stage_payer_plan_period ORDER BY person_id, payer_plan_period_start_date;
DROP TABLE stage_payer_plan_period;

CREATE TEMP TABLE stage_drug_era (LIKE omop.drug_era);
\copy stage_drug_era FROM PROGRAM 'gzip -dc drug_era.csv.gz' CSV HEADER NULL '' QUOTE '"';
INSERT INTO omop.drug_era SELECT * FROM stage_drug_era ORDER BY drug_concept_id, person_id, drug_era_start_date;
DROP TABLE stage_drug_era;

CREATE TEMP TABLE stage_dose_era (LIKE omop.dose_era);
\copy stage_dose_era FROM PROGRAM 'gzip -dc dose_era.csv.gz' CSV HEADER NULL '' QUOTE '"';
INSERT INTO omop.dose_era SELECT * FROM stage_dose_era ORDER BY drug_concept_id, person_id, dose_era_start_date;
DROP TABLE stage_dose_era;

CREATE TEMP TABLE stage_condition_era (LIKE omop.condition_era);
\copy stage_condition_era FROM PROGRAM 'gzip -dc condition_era.csv.gz' CSV HEADER NULL '' QUOTE '"';
INSERT INTO omop.condition_era SELECT * FROM stage_condition_era ORDER BY condition_concept_id, person_id, condition_era_start_date;
DROP TABLE stage_condition_era;

CREATE TEMP TABLE stage_episode (LIKE omop.episode);
\copy stage_episode FROM PROGRAM 'gzip -dc episode.csv.gz' CSV HEADER NULL '' QUOTE '"';
INSERT INTO omop.episode SELECT * FROM stage_episode ORDER BY episode_concept_id, person_id, episode_start_date;
DROP TABLE stage_episode;

ANALYZE;
