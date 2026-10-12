MIMIC-OMOP ON CITUS (SINGLE NODE)
=================================

Loads the MIMIC-OMOP export (`etl/Result`, produced by `make exporter`) into a
single-node [Citus](https://docs.citusdata.com/) database. The ETL itself still
runs on plain PostgreSQL.

Layout
------

- **Distributed tables**, sharded by `person_id` and co-located: `person` and all
  the person-centric event tables. Joins on `person_id` stay inside a shard, and a
  query runs on all shards in parallel. `note_nlp` has no `person_id` and is
  distributed by `note_id`.
- **Reference tables**: the vocabulary, health system, metadata and cohort tables.
- **Columnar storage** (zstd) for the event tables, which are append-only once
  loaded. `person` stays heap for single-row lookups, `note` because columnar does
  not TOAST large values.
- Columnar tables are loaded sorted by `<domain>_concept_id, person_id, <date>`, so
  that concept filters skip most chunks.
- All tables are logged: columnar cannot be unlogged, and unlogged tables are
  emptied after a crash.
- No foreign keys (columnar does not support them). Primary keys are optional, in
  `mimic-omop-citus-primary-keys.sql`, and include the distribution column as Citus
  requires.

Server settings
---------------

```
shared_preload_libraries = 'citus'
```

On a single node, the shards live on the coordinator and are queried through local
connections, one per shard:

- `shard_count` (import variable) should match the number of CPU cores.
- `citus.max_adaptive_executor_pool_size` (default 16) must be at least
  `shard_count` for a query to scan all shards at once.
- `citus.local_shared_pool_size` (default: half of `max_connections`) caps these
  connections across all sessions; size `max_connections` accordingly.

Import
------

```bash
make exporter
cd etl/Result
psql "dbname=mimic" -v shard_count=16 -f import_mimic_omop_citus.sql
# optional
psql "dbname=mimic options=--search_path=omop" -f mimic-omop-citus-primary-keys.sql
```

The import stages each columnar table in a temporary table to sort it: plan for
the temporary disk space of the largest table (`measurement`).
