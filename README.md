# bucket2bq
Create an inventory of objects in a single GCS Bucket and upload the inventory to Big Query.

This small applications discovers all the objects in a Google Cloud Storage bucket and creates an Avro file containing all the objects
and their attributes. This can be then imported into BigQuery.

### Usage

The program to create bucket inventory files can be run as an independent program. For example,

```bash
./bucket2bq -bucket "name-of-bucket-to-inventory"
```

It has several options:

```bash
./bucket2bq -help
GCS Bucket object metadata to BigQuery, version 0.1.0
Usage of ./bucket2bq:
  -alsologtostderr
        log to standard error as well as files
  -avro_schema string
        Avro schema (default: use embedded) (default "embedded")
  -bucket string
        bucket name (default "bucketname")
  -buffer_size int
        file buffer (default 1000)
  -concurrency int
        concurrency (GOMAXPROCS) (default 4)
  -file string
        output file name (default "gcs.avro")
  -log_backtrace_at value
        when logging hits line file:N, emit a stack trace
  -log_dir string
        If non-empty, write log files in this directory
  -logtostderr
        log to standard error instead of files
  -stderrthreshold value
        logs at or above this threshold go to stderr
  -v value
        log level for V logs
  -versions
        include GCS object versions
  -vmodule value
        comma-separated list of pattern=N settings for file-filtered logging
```

You can also use the supplied `run.sh` script, which creates the bucket inventory and uploads the inventory to a BigQuery table. This script accepts the following
environment variables as input:

- `BUCKET2BQ_BUCKET`: GCS bucket name to inventory.
- `BUCKET2BQ_PROJECT`: project ID where the scratch storage bucket and BigQuery dataset resides in
- `BUCKET2BQ_DATASET`: BigQuery dataset name (eg. `gcs2bq`)
- `BUCKET2BQ_TABLE`: BigQuery table name (eg. `objects`)
- `BUCKET2BQ_SCRATCH_BUCKET`: Bucket for storing the temporary Avro file to be loaded into BigQuery (no `gs://` prefix)
- `BUCKET2BQ_LOCATION`: Location for the bucket and dataset (if they need to be created, eg. `EU`)
- `BUCKET2BQ_VERSIONS`: Set to non-empty if you want to retrieve object versions as well

### Installing

Docker containers with this application are publicly available at `ghcr.io/brews/bucket2bq`.

You can also install the binary to create the inventory file on your computer by running:

```bash
go install github.com/brews/bucket2bq@latest
```

### Building

You can build it either manually, or using the supplied `Dockerfile`:

```bash
docker build -t bucket2bq .
```

## Support

Source code is available online at https://github.com/brews/bucket2gcs. 

Please file bugs in at https://github.com/brews/bucket2bq/issues.

This software is available under the Apache License, Version 2.0.

This software is a modification of the "gcs2bq" tool, available from https://github.com/GoogleCloudPlatform/professional-services/tree/main/tools/gcs2bq under an Apache-2.0 license.

