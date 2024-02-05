#! /bin/sh
# This script is used to backup a database to a file, so that it can be used to
# bootstrap the next loading process

# Check that everything is ready:
# Check Envvars
if [ -z "$FDS_LOADER_SOURCE_PATH" ]; then
    echo "ERROR: FDS_LOADER_SOURCE_PATH is not set."
    envvar_fail=1
fi

if [ -z "$PGDATABASE" ]; then
    echo "ERROR: PGDATABASE is not set."
    envvar_fail=1
fi

if [ -n "$envvar_fail" ]; then
    echo "One or more required envvars are not set."
    echo "Please set these envvars and try again."
    exit 1
fi

backups_dir="$FDS_LOADER_SOURCE_PATH/backups"
if [ ! -d "$backups_dir" ]; then
  echo "ERROR: Backups directory not found at $backups_dir"
  file_fail=1
fi

if [ -n "$file_fail" ]; then
  echo "One or more required files or directories do not exist."
  exit 1
fi

if [ -z "$RESTORE_FILE" ]; then
  restorefile=$(find "$backups_dir" -type f | sort -t "-" -k 2 -nr | head -n 1)
else
  restorefile="$backups_dir/$RESTORE_FILE"
  if [ ! -f "$restorefile" ]; then
    echo "ERROR: Restore file not found at $restorefile"
    exit 1
  fi
fi

echo "INFO: pg_restore-ing database from $restorefile"

pg_restore \
  --dbname="$PGDATABASE" \
  --jobs="$MACHINE_CORES" \
  --verbose \
  "$restorefile"
