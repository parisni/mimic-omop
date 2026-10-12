OMOP_SCHEMA=omop
MIMIC="host=$(DB_HOST) dbname=mimic user=postgres options=--search_path=$(MIMIC_SCHEMA),public"
OMOP="host=$(DB_HOST) dbname=mimic user=postgres options=--search_path=$(OMOP_SCHEMA),public"

build: buildmimic buildomop
runetl: sequence concept load
runetlprivate: runetl private

buildmimic:
	cd mimic/build-mimic &&\
	psql $(MIMIC) -v mimic_data_dir="$(MIMIC_DATA_DIR)"  -f build-$(MIMIC_SCHEMA).sql &&\
	psql $(MIMIC) -v mimic_data_dir="$(MIMIC_DATA_DIR)"  -f postgres_add_indexes.sql &&\
	psql $(MIMIC) -v mimic_data_dir="$(MIMIC_DATA_DIR)"  -f analyze.sql

# Comments run after mimic-omop-alter.sql since they also document its extra columns.
buildomop:
	psql $(OMOP) -c "DROP SCHEMA IF EXISTS $(OMOP_SCHEMA) CASCADE; CREATE SCHEMA $(OMOP_SCHEMA);" &&\
	psql $(OMOP) -f omop/build-omop/postgresql/OMOPCDM_postgresql_5.4_ddl.sql &&\
	psql $(OMOP) -f omop/build-omop/postgresql/mimic-omop-alter.sql &&\
	psql $(OMOP) -f omop/build-omop/postgresql/omop_cdm_comments.sql &&\
	psql $(OMOP) -f omop/build-omop/postgresql/omop_vocab_load.sql &&\
	psql $(OMOP) -f omop/build-omop/postgresql/OMOPCDM_postgresql_5.4_indices_vocabulary.sql &&\
	psql $(OMOP) --set=OMOP_SCHEMA="$(OMOP_SCHEMA)" -f "omop/build-omop/postgresql/analyze.sql"

concept:
	Rscript --vanilla etl/ConceptTables/loadTables.R $(MIMIC_SCHEMA)

sequence: 
	psql $(MIMIC) --set=OMOP_SCHEMA="$(OMOP_SCHEMA)"  -f mimic/build-mimic/postgres_create_mimic_id.sql

load: 
	psql $(MIMIC) --set=OMOP_SCHEMA="$(OMOP_SCHEMA)" -f etl/etl.sql 

private: 
	psql  $(MIMIC) --set=OMOP_SCHEMA="$(OMOP_SCHEMA)" -f etl/etl_contrib.sql 

check:
	psql $(MIMIC) --set=OMOP_SCHEMA="$(OMOP_SCHEMA)" -f etl/check_etl.sql 

exporter:
	mkdir -p etl/Result &&\
	psql $(MIMIC)  --set=OMOP_SCHEMA="$(OMOP_SCHEMA)" -f export/export_mimic_omop.sql &&\
	cp import/import_mimic_omop.sql etl/Result/ &&\
	cp omop/build-omop/postgresql/* etl/Result/ &&\
	cp import/import_mimic_omop_citus.sql omop/build-omop/citus/*.sql etl/Result/
#	tar -cf $(MIMIC_SCHEMA)-omop.tar etl/Result/

exportmonet:
	mkdir -p etl/Result &&\
	psql $(MIMIC) --set=OMOP_SCHEMA="$(OMOP_SCHEMA)" -f export/export_mimic_omop_monetdb.sql &&\
	cp import/import_mimic_omop_monetdb.sh etl/Result/ &&\
	cp omop/build-omop/monetdb/ddl_monetdb.sql etl/Result/
#	tar -cf $(MIMIC_SCHEMA)-omop.tar etl/Result/
	
exportmonetdenorm:
	mkdir -p etl/Result &&\
	psql $(MIMIC) --set=OMOP_SCHEMA="$(OMOP_SCHEMA)" -f export/export_mimic_omop_monetdb_denorm.sql &&\
	cp import/import_mimic_omop_monetdb.sh etl/Result/ &&\
	cp omop/build-omop/monetdb/ddl_monetdb_denorm.sql etl/Result/

purgeresult:
	find etl/Result/ -name "*.gz" -delete &&\
	find etl/Result/ -name "*.tar" -delete &&\
	find etl/Result/ -name "*.sql" -delete 
