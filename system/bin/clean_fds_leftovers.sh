#! /bin/sh
# This file is used to clean the leftover directories
# and tables from running FDSLoader64
#
# Check that everything is ready:
# Check Envvars
if [ -z "$PGHOST" ]; then
    echo "ERROR: PGHOST is not set."
    envvar_fail=1
fi

if [ -z "$PGUSER" ]; then
    echo "ERROR: PGUSER is not set."
    envvar_fail=1
fi

if [ -z "$PGPASSWORD" ]; then
    echo "ERROR: PGPASSWORD is not set."
    envvar_fail=1
fi

if [ -n "$envvar_fail" ]; then
    echo "One or more required envvars are not set."
    echo "Please set these envvars and try again."
    exit 1
fi


echo "INFO: Cleaning up FDS directories"

if [ -d "zips" ]; then
  echo "INFO: Removing zips directory"
  rm -r zips
else
  echo "INFO: No zips directory found"
fi

if [ -d "schemas" ]; then
  echo "INFO: Removing schemas directory"
  rm -r schemas
else
  echo "INFO: No schemas directory found"
fi

if [ -d "temp" ]; then
  echo "INFO: Removing temp directory"
  rm -r temp
else
  echo "INFO: No temp directory found"
fi

if [ -d "zips" ]; then
  echo "INFO: Removing data directory"
  rm -r data
else
  echo "INFO: No data directory found"
fi

echo "INFO: Cleaning scratch schema from database"

  # running wait-for to wait for database to start up before attempting to connect
  echo "INFO: Waiting for database port to be available"
  # using if ! cmd to test for failure. See: https://www.shellcheck.net/wiki/SC2181
  if ! wait-for.sh "$PGHOST:5432" -t 120; then
    exit_code="$?"
    echo "ERROR: Open port not found at $PGHOST:5432"
    echo "Exiting. (exit code $exit_code)"
    exit "$exit_code"
  fi

# using if ! cmd to test for failure. See: https://www.shellcheck.net/wiki/SC2181
if ! scratch_count_pre=$(
  echo "SELECT count(*) FROM information_schema.tables where table_schema = 'fds_scratch';" | \
    isql -v -b -d: FDSLoader "$PGUSER" "$PGPASSWORD"
      ); then
      exit_code="$?"
      echo "ERROR: Database connection failed. isql output follows:"
      echo "$scratch_count_pre"
      echo "Exiting. (exit code $exit_code)"
      exit "$exit_code"
    else
      echo "INFO: found $scratch_count_pre scratch tables"
fi

if [ "$scratch_count_pre" -gt 0 ]; then
  echo "INFO: Dropping scratch tables (with CASCADE)"
  if ! drop_output=$(
    echo " \
      BEGIN; \
      SET TRANSACTION READ WRITE; \
      DROP SCHEMA fds_scratch CASCADE; \
      COMMIT; \
      " | \
      isql -v -b -d: FDSLoader "$PGUSER" "$PGPASSWORD"
          ); then
          exit_code="$?"
          echo "ERROR: Database connection failed. isql output follows:"
          echo "$drop_output"
        else
          echo "fds_scratch schema (CASCADE) dropped."
          scratch_count_post=$(
          echo " \
            SELECT count(*) \
            FROM information_schema.tables \
            where table_schema = 'fds_scratch' \
            ;" | \
            isql -v -b -d: FDSLoader "$PGUSER" "$PGPASSWORD"
          )
          echo "INFO: found $scratch_count_post scratch tables"
  fi
fi

