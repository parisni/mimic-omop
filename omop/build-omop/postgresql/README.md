HOW TO BUILD
============

Clone the mimic-omop repository:

```bash
git clone git@github.com:MIT-LCP/mimic-omop.git
cd mimic-omop
```

All the following commands are assumed to be run in the root path of the repository, i.e. the mimic-omop folder you just cloned and changed into.

`make buildomop` runs all the steps below; they are detailed here to build the schema by hand.

OMOP CDM DDL
------------

The `OMOPCDM_postgresql_5.4_*.sql` files are the OHDSI [CDM v5.4.3](https://github.com/OHDSI/CommonDataModel/releases/tag/v5.4.3)
PostgreSQL scripts, slightly adapted. To regenerate them (e.g. for a new CDM patch release):

```bash
git clone --branch v5.4.3 https://github.com/OHDSI/CommonDataModel.git
DIR=omop/build-omop/postgresql
for kind in ddl primary_keys constraints indices; do
  sed 's/@cdmDatabaseSchema\.//g' CommonDataModel/inst/ddl/5.4/postgresql/OMOPCDM_postgresql_5.4_$kind.sql > $DIR/OMOPCDM_postgresql_5.4_$kind.sql
done
# unlogged tables speed up the ETL
sed -i 's/^CREATE TABLE /CREATE UNLOGGED TABLE /' $DIR/OMOPCDM_postgresql_5.4_ddl.sql
# vocabulary indices are needed by the ETL, the others are only built afterwards
csplit -s -f $DIR/indices $DIR/OMOPCDM_postgresql_5.4_indices.sql '/^Standardized vocabularies/-1'
mv $DIR/indices00 $DIR/OMOPCDM_postgresql_5.4_indices_clinical.sql
mv $DIR/indices01 $DIR/OMOPCDM_postgresql_5.4_indices_vocabulary.sql
rm $DIR/OMOPCDM_postgresql_5.4_indices.sql
```

The schema prefix is removed: the scripts rely on the `search_path` of the connection.

Build
-----

Define the PSQL connection parameters you would like to use.

```bash
export OMOP_SCHEMA='omop'
export OMOP='host=localhost dbname=postgres user=postgres options=--search_path='$OMOP_SCHEMA
# or, e.g., export OMOP='dbname=mimic options=--search_path='$OMOP_SCHEMA
```

Build the schema:

```bash
psql "$OMOP" -c "DROP SCHEMA IF EXISTS $OMOP_SCHEMA CASCADE;"
psql "$OMOP" -c "CREATE SCHEMA $OMOP_SCHEMA;"
psql "$OMOP" -f "omop/build-omop/postgresql/OMOPCDM_postgresql_5.4_ddl.sql"
```

Apply the MIMIC-OMOP deviations from the CDM: character columns become `text` (no performance degradation),
some NOT NULL constraints are relaxed, and a few columns and tables are added (see the file for details):

```bash
psql "$OMOP" -f "omop/build-omop/postgresql/mimic-omop-alter.sql"
```

We add some comments to the data model (after the alter script, as they also document the added columns):

```bash
psql "$OMOP" -f "omop/build-omop/postgresql/omop_cdm_comments.sql"
```

Symlink your vocabulary folder so that the `extras/athena` path symlinks to it, e.g.:

```bash
ln -s /data/vocab/ extras/athena
```

Above my `/data/vocab/` folder contains `CONCEPT_ANCESTOR.csv`, `CONCEPT_CPT4.csv`, `CONCEPT.csv`, etc.

Note: you can download the vocabulary from here: https://athena.ohdsi.org/
Don't forget to run the java file to import CPT codes into the concept folder after you download the vocabulary.

Import the vocabulary and index it (the ETL relies on these indices):

```bash
psql "$OMOP" -f "omop/build-omop/postgresql/omop_vocab_load.sql"
psql "$OMOP" -f "omop/build-omop/postgresql/OMOPCDM_postgresql_5.4_indices_vocabulary.sql"
```

(Optional) Primary keys and the other indices slow down the ETL - so you may want to only build these *after* running the full ETL.

```bash
psql "$OMOP" -f "omop/build-omop/postgresql/OMOPCDM_postgresql_5.4_primary_keys.sql"
psql "$OMOP" -f "omop/build-omop/postgresql/OMOPCDM_postgresql_5.4_indices_clinical.sql"
```

(Optional, experimental) For a similar reason as above, you may want to run this after the full ETL. Note also that since the foreign keys were not used during the construction of the ETL, they may have been violated by the process.

```bash
psql "$OMOP" -f "omop/build-omop/postgresql/OMOPCDM_postgresql_5.4_constraints.sql"
```
