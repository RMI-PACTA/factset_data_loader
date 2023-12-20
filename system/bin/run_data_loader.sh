#! /bin/sh
# This script is used to run the FactSet data loader in a docker container.


# Install DSN
# This script should be on $PATH (docker should put it as /usr/local/bin/)
if ! setup_DSN.sh; then
  exit_code="$?"
  echo "ERROR: DSN Setup script did not run cleanly"
  echo "Exiting. (exit code $exit_code)"
  exit "$exit_code"
fi

# Copy and unzip FDSLoader Application
# Includes preparing Config file
# This script should be on $PATH (docker should put it as /usr/local/bin/)
if ! prepare_FDSLoader.sh; then
  exit_code="$?"
  echo "ERROR: FDSLoader setup script did not run cleanly"
  echo "Exiting. (exit code $exit_code)"
  exit "$exit_code"
fi

# Check that everything is ready:
# Check Envvars
if [ -z "$FDS_LOADER_PATH" ]; then
    echo "ERROR: FDS_LOADER_PATH is not set."
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

fds_loader_binary="$FDS_LOADER_PATH/FDSLoader64" 
key_file="$FDS_LOADER_PATH/key.txt"
config_file="$FDS_LOADER_PATH/config.xml"

if [ ! -x "$fds_loader_binary" ]; then
  echo "ERROR: FDSLoader binary not found at $fds_loader_binary or is not executable."
  file_fail=1
fi

if [ ! -f "$key_file" ]; then
  echo "ERROR: Key file not found at $key_file"
  file_fail=1
fi

if [ ! -f "$config_file" ]; then
  echo "ERROR: Config file not found at $config_file"
  file_fail=1
fi

if [ -n "$file_fail" ]; then
  echo "One or more required files or directories do not exist."
  exit 1
fi

if [ -n "$RESTORE_DB" ]; then
  echo "INFO: Restoring database from backup"
  if ! backup_restore.sh; then
    exit_code="$?"
    echo "ERROR: Database did not restore cleanly"
    echo "Exiting. (exit code $exit_code)"
    exit "$exit_code"
  fi
fi

test_results="$FDS_LOADER_PATH/test_results.txt"
support_path="$FDS_LOADER_SOURCE_PATH/support_$(date +%Y%m%d_%H%M%S)"

## Run FDSLoader with tests
echo "INFO: Running FDSLoader in test mode"
if ! "$fds_loader_binary" --test 2>&1 | tee "$test_results"; then
  exit_code="$?"
  echo "ERROR: FDSLoader did not run cleanly"
  echo "Exiting. (exit code $exit_code)"
  exit "$exit_code"
fi

## --test always exits 0, so using grep to inspect results
test_errors=$(grep -c "ERROR" "$test_results")
if [ "$test_errors" -gt 0 ]; then
  echo "ERROR: FDSLoader test run completed with errors"
  mkdir -p "$support_path"
  cp "$test_results" "$support_path"
  exit 1
else
  echo "INFO: FDSLoader test run completed successfully"
fi

# clean FDSLoader context
clean_fds_leftovers.sh

# Run FDSLoader for real
echo "INFO: Running FDSLoader in production mode"
prod_results="$FDS_LOADER_PATH/prod_results.txt"
if ! "$fds_loader_binary" 2>&1 | tee "$prod_results"; then
  exit_code="$?"
  echo "ERROR: FDSLoader did not run cleanly"
  echo "Exiting. (exit code $exit_code)"
  exit "$exit_code"
fi

## --FDSLoader64 always exits 0, so using grep to inspect results
prod_errors=$(grep -c "ERROR" "$prod_results")
if [ "$prod_errors" -gt 0 ]; then
  echo "ERROR: FDSLoader run completed with errors"
  echo "INFO: Generating Support logs"
  "$fds_loader_binary" --support --support-logs-max 5
  mkdir -p "$support_path"
  cp "$test_results" "$support_path"
  cp "$prod_results" "$support_path"
  cp support_*.zip "$support_path"
  exit 1
else
  echo "INFO: FDSLoader run completed successfully"
fi


if [ -n "$BACKUP_DB" ]; then
  # Backup Database
  # This script should be on $PATH (docker should put it as /usr/local/bin/)
  if ! backup_database.sh; then
    exit_code="$?"
    echo "ERROR: Database did not backup cleanly cleanly"
    echo "Exiting. (exit code $exit_code)"
    exit "$exit_code"
  fi
fi

echo "INFO: Done!"
exit 0
