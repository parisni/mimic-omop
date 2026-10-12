-- Turns the MIMIC-OMOP schema into a Citus single-node layout.
-- To run on the empty tables, after the CDM DDL and mimic-omop-alter.sql.

\set ON_ERROR_STOP true

-- Set it to the number of CPU cores (psql -v shard_count=N): each shard is scanned by its own backend.
\if :{?shard_count}
\else
\set shard_count 16
\endif

-- Columnar tables cannot be unlogged, and an unlogged table is emptied after a crash.
DO $$
DECLARE
  tbl record;
BEGIN
  FOR tbl IN
    SELECT relname FROM pg_class
     WHERE relnamespace = current_schema()::regnamespace
       AND relkind = 'r' AND relpersistence = 'u'
  LOOP
    EXECUTE format('ALTER TABLE %I SET LOGGED', tbl.relname);
  END LOOP;
END
$$;

-- Event tables are append-only once loaded: columnar compresses them and skips unread columns.
-- person stays heap for single-row lookups, note because columnar does not TOAST large texts.
SELECT alter_table_set_access_method('observation_period', 'columnar');
SELECT alter_table_set_access_method('visit_occurrence', 'columnar');
SELECT alter_table_set_access_method('visit_detail', 'columnar');
SELECT alter_table_set_access_method('condition_occurrence', 'columnar');
SELECT alter_table_set_access_method('drug_exposure', 'columnar');
SELECT alter_table_set_access_method('procedure_occurrence', 'columnar');
SELECT alter_table_set_access_method('device_exposure', 'columnar');
SELECT alter_table_set_access_method('measurement', 'columnar');
SELECT alter_table_set_access_method('observation', 'columnar');
SELECT alter_table_set_access_method('death', 'columnar');
SELECT alter_table_set_access_method('note_nlp', 'columnar');
SELECT alter_table_set_access_method('specimen', 'columnar');
SELECT alter_table_set_access_method('payer_plan_period', 'columnar');
SELECT alter_table_set_access_method('drug_era', 'columnar');
SELECT alter_table_set_access_method('dose_era', 'columnar');
SELECT alter_table_set_access_method('condition_era', 'columnar');
SELECT alter_table_set_access_method('episode', 'columnar');

-- Vocabulary and lookup tables are joined from every shard.
SELECT create_reference_table('concept');
SELECT create_reference_table('vocabulary');
SELECT create_reference_table('domain');
SELECT create_reference_table('concept_class');
SELECT create_reference_table('concept_relationship');
SELECT create_reference_table('relationship');
SELECT create_reference_table('concept_synonym');
SELECT create_reference_table('concept_ancestor');
SELECT create_reference_table('source_to_concept_map');
SELECT create_reference_table('drug_strength');
SELECT create_reference_table('cdm_source');
SELECT create_reference_table('metadata');
SELECT create_reference_table('location');
SELECT create_reference_table('care_site');
SELECT create_reference_table('provider');
SELECT create_reference_table('cost');
SELECT create_reference_table('fact_relationship');
SELECT create_reference_table('episode_event');
SELECT create_reference_table('cohort');
SELECT create_reference_table('cohort_definition');
SELECT create_reference_table('cohort_attribute');
SELECT create_reference_table('attribute_definition');

SET citus.shard_count = :shard_count;

SELECT create_distributed_table('person', 'person_id');
SELECT create_distributed_table('observation_period', 'person_id', colocate_with => 'person');
SELECT create_distributed_table('visit_occurrence', 'person_id', colocate_with => 'person');
SELECT create_distributed_table('visit_detail', 'person_id', colocate_with => 'person');
SELECT create_distributed_table('condition_occurrence', 'person_id', colocate_with => 'person');
SELECT create_distributed_table('drug_exposure', 'person_id', colocate_with => 'person');
SELECT create_distributed_table('procedure_occurrence', 'person_id', colocate_with => 'person');
SELECT create_distributed_table('device_exposure', 'person_id', colocate_with => 'person');
SELECT create_distributed_table('measurement', 'person_id', colocate_with => 'person');
SELECT create_distributed_table('observation', 'person_id', colocate_with => 'person');
SELECT create_distributed_table('death', 'person_id', colocate_with => 'person');
SELECT create_distributed_table('note', 'person_id', colocate_with => 'person');
SELECT create_distributed_table('specimen', 'person_id', colocate_with => 'person');
SELECT create_distributed_table('payer_plan_period', 'person_id', colocate_with => 'person');
SELECT create_distributed_table('drug_era', 'person_id', colocate_with => 'person');
SELECT create_distributed_table('dose_era', 'person_id', colocate_with => 'person');
SELECT create_distributed_table('condition_era', 'person_id', colocate_with => 'person');
SELECT create_distributed_table('episode', 'person_id', colocate_with => 'person');

-- note_nlp has no person_id; note_id keeps the sections of a note in the same shard.
SELECT create_distributed_table('note_nlp', 'note_id', colocate_with => 'none');
