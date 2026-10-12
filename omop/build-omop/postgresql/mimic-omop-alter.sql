-- MIMIC-OMOP deviations from the OMOP CDM 5.4 DDL.
-- Only additive or relaxing changes: every CDM 5.4 table and column is kept.

-- Postgres has no performance gain on bounded varchar, and the bounds make loading error prone.
DO $$
DECLARE
  col record;
BEGIN
  FOR col IN
    SELECT table_name, column_name
      FROM information_schema.columns
     WHERE table_schema = current_schema()
       AND data_type = 'character varying'
  LOOP
    EXECUTE format('ALTER TABLE %I ALTER COLUMN %I TYPE text', col.table_name, col.column_name);
  END LOOP;
END
$$;

ALTER TABLE observation_period ADD COLUMN observation_period_start_datetime TIMESTAMP NOT NULL;
ALTER TABLE observation_period ADD COLUMN observation_period_end_datetime TIMESTAMP NOT NULL;

-- CDM 5.4 only keeps the standard concept for admission/discharge places; these hold the MIMIC local concept.
ALTER TABLE visit_occurrence ADD COLUMN admitted_from_source_concept_id integer;
ALTER TABLE visit_occurrence ADD COLUMN discharged_to_source_concept_id integer;
ALTER TABLE visit_detail ADD COLUMN admitted_from_source_concept_id integer;
ALTER TABLE visit_detail ADD COLUMN discharged_to_source_concept_id integer;

ALTER TABLE dose_era ADD COLUMN temporal_unit_concept_id integer;
COMMENT ON COLUMN dose_era.temporal_unit_concept_id  IS 'Stores temporal unit, daily, hourly ...';

ALTER TABLE dose_era ADD COLUMN temporal_value numeric;
COMMENT ON COLUMN dose_era.temporal_value IS 'Stores temporal value';

ALTER TABLE drug_exposure ADD COLUMN quantity_source_value text;
COMMENT ON COLUMN drug_exposure.quantity_source_value IS 'Stores the source quantity value';

-- mimic does not provide some dates for drugs.
-- this allows populating them
ALTER TABLE drug_exposure ALTER COLUMN drug_exposure_start_date DROP NOT NULL;
ALTER TABLE drug_exposure ALTER COLUMN drug_exposure_end_date DROP NOT NULL;
ALTER TABLE dose_era ALTER COLUMN dose_era_start_date DROP NOT NULL;
ALTER TABLE dose_era ALTER COLUMN dose_era_end_date DROP NOT NULL;

-- A single "offset" cannot locate a section, cf http://forums.ohdsi.org/t/note-nlp-questions/3379/4
-- "offset" is kept, left empty, so that the table still matches the CDM.
ALTER TABLE note_nlp ADD COLUMN offset_begin integer;
ALTER TABLE note_nlp ADD COLUMN offset_end integer;
ALTER TABLE note_nlp ADD COLUMN section_source_value text;
ALTER TABLE note_nlp ADD COLUMN section_source_concept_id integer;

-- Dropped from CDM 5.4, kept to store the MIMIC derived attributes (callout and stay delays).
CREATE UNLOGGED TABLE attribute_definition (
  attribute_definition_id   integer NOT NULL,
  attribute_name            text    NOT NULL,
  attribute_description     text    NULL,
  attribute_type_concept_id integer NOT NULL,
  attribute_syntax          text    NULL
);

CREATE UNLOGGED TABLE cohort_attribute (
  cohort_definition_id    integer NOT NULL,
  subject_id              integer NOT NULL,
  cohort_start_date       date    NOT NULL,
  cohort_end_date         date    NOT NULL,
  attribute_definition_id integer NOT NULL,
  value_as_number         numeric NULL,
  value_as_concept_id     integer NULL
);

-- Below are columns we are considering adding

--ALTER TABLE death ADD COLUMN visit_detail_id BIGINT;
--COMMENT ON COLUMN death.visit_detail_id             IS '[CONTRIB] A foreign key to the visit in the VISIT_DETAIL table during where the death occured';

--ALTER TABLE death ADD COLUMN visit_occurrence_id BIGINT;
--COMMENT ON COLUMN death.visit_occurrence_id             IS '[CONTRIB] A foreign key to the visit in the VISIT_OCCURRENCE table during where the death occured';
--
--ALTER TABLE death ADD COLUMN death_visit_detail_delay double precision;
--COMMENT ON COLUMN death.death_visit_detail_delay             IS '[CONTRIB] Difference between deathtime and visit_start_datetime of VISIT_DETAIL table';
--
--ALTER TABLE death ADD COLUMN death_visit_occurrence_delay double precision;
--COMMENT ON COLUMN death.death_visit_occurrence_delay      IS '[CONTRIB] Difference between deathtime and visit_start_datetime of VISIT_OCCURRENCE table';
--
--ALTER TABLE measurement ADD COLUMN quality_concept_id bigint;
--COMMENT ON COLUMN measurement.quality_concept_id             IS '[CONTRIB] Quality mask, can be queried with regex, to filter based on quality aspects';
--
--ALTER TABLE visit_occurrence ADD COLUMN age_in_year integer;
--COMMENT ON COLUMN visit_occurrence.age_in_year             IS '[CONTRIB] Age at visit';
--
--ALTER TABLE visit_occurrence ADD COLUMN age_in_month integer;
--COMMENT ON COLUMN visit_occurrence.age_in_month             IS '[CONTRIB] Age at visit';
--
--ALTER TABLE visit_occurrence ADD COLUMN age_in_day integer;
--COMMENT ON COLUMN visit_occurrence.age_in_day IS '[CONTRIB] Age at visit';
--
--ALTER TABLE visit_occurrence ADD COLUMN visit_occurrence_length double precision;
--COMMENT ON COLUMN visit_occurrence.visit_occurrence_length IS '[CONTRIB] Length of visit occurrence';
--
--ALTER TABLE visit_detail ADD COLUMN visit_detail_length double precision;
--COMMENT ON COLUMN visit_detail.visit_detail_length IS '[CONTRIB] Length of visit detail';
--
--ALTER TABLE visit_detail ADD COLUMN discharge_delay double precision;
--COMMENT ON COLUMN visit_detail.discharge_delay IS '[CONTRIB] Delay between discharge decision and effective discharge';
