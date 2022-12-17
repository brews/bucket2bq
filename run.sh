#!/bin/bash

# For running in container
if [ "${HOME}" == "/" ] ; then
    export HOME=/home
fi

error() {
    echo "ERROR: $1" >&2
    exit 2
}

if [ -n "${GOOGLE_PROJECT}" ]
then
    export BUCKET2BQ_PROJECT="${GOOGLE_PROJECT}"
fi

if [ -z "${BUCKET2BQ_PROJECT}" ]
then
    error "Error: Missing BigQuery project (set environment variable BUCKET2BQ_PROJECT)." 1
fi
if [ -z "${BUCKET2BQ_DATASET}" ]
then
    error "Error: Missing BigQuery dataset (set environment variable BUCKET2BQ_DATASET)." 1
fi
if [ -z "${BUCKET2BQ_TABLE}" ]
then
    error "Error: Missing BigQuery table (set environment variable BUCKET2BQ_TABLE)." 1
fi
if [ -z "${BUCKET2BQ_BUCKET}" ]
then
    error "Error: Missing target GCS bucket (set environment variable BUCKET2BQ_BUCKET)." 1
fi
if [ -z "${BUCKET2BQ_SCRATCH_BUCKET}" ]
then
    error "Error: Missing scratch GCS bucket (set environment variable BUCKET2BQ_SCRATCH_BUCKET)." 1
fi
if [ -z "${BUCKET2BQ_LOCATION}" ]
then
    error "Error: Missing GCS bucket/BQ dataset location (set environment variable BUCKET2BQ_LOCATION)." 1
fi

BUCKET2BQ_FILE=$(mktemp)
BUCKET2BQ_FILE="${BUCKET2BQ_FILE}.avro"
BUCKET2BQ_FILENAME=$(basename "$BUCKET2BQ_FILE")
BUCKET2BQ_FLAGS="-logtostderr -bucket ${BUCKET2BQ_BUCKET} -file ${BUCKET2BQ_FILE}"
if [ -n "${BUCKET2BQ_VERSIONS}" ]
then
    BUCKET2BQ_FLAGS="${BUCKET2BQ_FLAGS} -versions"
fi

# Intentionally split args by space.
# TODO: use array expansion, instead.
# shellcheck disable=SC2086
./bucket2bq $BUCKET2BQ_FLAGS || error "Export failed!" 2

gsutil mb -p "${BUCKET2BQ_PROJECT}" -c standard -l "${BUCKET2BQ_LOCATION}" -b on "gs://${BUCKET2BQ_SCRATCH_BUCKET}" || echo "Info: Storage bucket already exists: ${BUCKET2BQ_SCRATCH_BUCKET}"

gsutil cp "${BUCKET2BQ_FILE}" "gs://${BUCKET2BQ_SCRATCH_BUCKET}/${BUCKET2BQ_FILENAME}" || error "Failed copying ${BUCKET2BQ_FILE} to gs://${BUCKET2BQ_SCRATCH_BUCKET}/${BUCKET2BQ_FILENAME}!" 3

bq mk --project_id="${BUCKET2BQ_PROJECT}" --location="${BUCKET2BQ_LOCATION}" "${BUCKET2BQ_DATASET}" || echo "Info: BigQuery dataset already exists: ${BUCKET2BQ_DATASET}"

bq load --project_id="${BUCKET2BQ_PROJECT}" --location="${BUCKET2BQ_LOCATION}" --schema bigquery.schema --source_format=AVRO --use_avro_logical_types --replace=true "${BUCKET2BQ_DATASET}.${BUCKET2BQ_TABLE}" "gs://${BUCKET2BQ_SCRATCH_BUCKET}/${BUCKET2BQ_FILENAME}" || \
  error "Failed to load gs://${BUCKET2BQ_SCRATCH_BUCKET}/${BUCKET2BQ_FILENAME} to BigQuery table ${BUCKET2BQ_DATASET}.${BUCKET2BQ_TABLE}!" 4

gsutil rm "gs://${BUCKET2BQ_SCRATCH_BUCKET}/${BUCKET2BQ_FILENAME}" || error "Failed deleting gs://${BUCKET2BQ_SCRATCH_BUCKET}/${BUCKET2BQ_FILENAME}!" 5

rm -f "${BUCKET2BQ_FILE}"
