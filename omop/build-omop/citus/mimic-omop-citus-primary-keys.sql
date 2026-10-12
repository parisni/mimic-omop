-- CDM 5.4 primary keys, adapted to Citus: a distributed table key must include its distribution column.
-- Optional, to run after the import: building them on the large columnar tables takes time and space.

ALTER TABLE person ADD CONSTRAINT xpk_person PRIMARY KEY (person_id);
ALTER TABLE observation_period ADD CONSTRAINT xpk_observation_period PRIMARY KEY (person_id, observation_period_id);
ALTER TABLE visit_occurrence ADD CONSTRAINT xpk_visit_occurrence PRIMARY KEY (person_id, visit_occurrence_id);
ALTER TABLE visit_detail ADD CONSTRAINT xpk_visit_detail PRIMARY KEY (person_id, visit_detail_id);
ALTER TABLE condition_occurrence ADD CONSTRAINT xpk_condition_occurrence PRIMARY KEY (person_id, condition_occurrence_id);
ALTER TABLE drug_exposure ADD CONSTRAINT xpk_drug_exposure PRIMARY KEY (person_id, drug_exposure_id);
ALTER TABLE procedure_occurrence ADD CONSTRAINT xpk_procedure_occurrence PRIMARY KEY (person_id, procedure_occurrence_id);
ALTER TABLE device_exposure ADD CONSTRAINT xpk_device_exposure PRIMARY KEY (person_id, device_exposure_id);
ALTER TABLE measurement ADD CONSTRAINT xpk_measurement PRIMARY KEY (person_id, measurement_id);
ALTER TABLE observation ADD CONSTRAINT xpk_observation PRIMARY KEY (person_id, observation_id);
ALTER TABLE note ADD CONSTRAINT xpk_note PRIMARY KEY (person_id, note_id);
ALTER TABLE note_nlp ADD CONSTRAINT xpk_note_nlp PRIMARY KEY (note_id, note_nlp_id);
ALTER TABLE specimen ADD CONSTRAINT xpk_specimen PRIMARY KEY (person_id, specimen_id);
ALTER TABLE location ADD CONSTRAINT xpk_location PRIMARY KEY (location_id);
ALTER TABLE care_site ADD CONSTRAINT xpk_care_site PRIMARY KEY (care_site_id);
ALTER TABLE provider ADD CONSTRAINT xpk_provider PRIMARY KEY (provider_id);
ALTER TABLE payer_plan_period ADD CONSTRAINT xpk_payer_plan_period PRIMARY KEY (person_id, payer_plan_period_id);
ALTER TABLE cost ADD CONSTRAINT xpk_cost PRIMARY KEY (cost_id);
ALTER TABLE drug_era ADD CONSTRAINT xpk_drug_era PRIMARY KEY (person_id, drug_era_id);
ALTER TABLE dose_era ADD CONSTRAINT xpk_dose_era PRIMARY KEY (person_id, dose_era_id);
ALTER TABLE condition_era ADD CONSTRAINT xpk_condition_era PRIMARY KEY (person_id, condition_era_id);
ALTER TABLE episode ADD CONSTRAINT xpk_episode PRIMARY KEY (person_id, episode_id);
ALTER TABLE metadata ADD CONSTRAINT xpk_metadata PRIMARY KEY (metadata_id);
ALTER TABLE concept ADD CONSTRAINT xpk_concept PRIMARY KEY (concept_id);
ALTER TABLE domain ADD CONSTRAINT xpk_domain PRIMARY KEY (domain_id);
ALTER TABLE concept_class ADD CONSTRAINT xpk_concept_class PRIMARY KEY (concept_class_id);
ALTER TABLE relationship ADD CONSTRAINT xpk_relationship PRIMARY KEY (relationship_id);
