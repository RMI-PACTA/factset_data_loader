#! /bin/sh
# This script is used to backup a database to a file, so that it can be used to
# bootstrap the next loading process

# Check that everything is ready:
# Check Envvars
if [ -z "$DEPLOY_START_TIME" ]; then
    echo "ERROR: DEPLOY_START_TIME is not set."
    envvar_fail=1
fi

if [ -z "$FDS_LOADER_SOURCE_PATH" ]; then
    echo "ERROR: FDS_LOADER_SOURCE_PATH is not set."
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


backupfile="$backups_dir/backup-$DEPLOY_START_TIME-custom.pgdump"
echo "INFO: pg_dump-ing database to $backupfile"

pg_dump --file="$backupfile" --format=custom --verbose
