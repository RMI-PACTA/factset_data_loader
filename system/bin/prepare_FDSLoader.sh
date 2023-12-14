#! /bin/sh

echo "INFO: Preparing FactSet Data Loader"

# This script is used to prepare the FactSet data loader in a docker container.
# it requires some envvars to be set prior to running.
# Let's check those now before we actually do anything

if [ -z "$FACTSET_SERIAL" ]; then
    echo "ERROR: FACTSET_SERIAL is not set."
    envvar_fail=1
fi

if [ -z "$FACTSET_USER" ]; then
    echo "ERROR: FACTSET_USER is not set."
    envvar_fail=1
fi

if [ -z "$FDS_LOADER_SOURCE_PATH" ]; then
    echo "ERROR: FDS_LOADER_SOURCE_PATH is not set."
    envvar_fail=1
fi

if [ -z "$FDS_LOADER_PATH" ]; then
    echo "ERROR: FDS_LOADER_PATH is not set."
    envvar_fail=1
fi

if [ -z "$FDS_LOADER_ZIP_FILENAME" ]; then
    echo "ERROR: FDS_LOADER_ZIP_FILENAME is not set."
    envvar_fail=1
fi

if [ -z "$MACHINE_CORES" ]; then
    echo "ERROR: MACHINE_CORES is not set."
    envvar_fail=1
fi

if [ -z "$PGDATABASE" ]; then
    echo "ERROR: PGDATABASE is not set."
    envvar_fail=1
fi

if [ -z "$PGPASSWORD" ]; then
    echo "ERROR: PGPASSWORD is not set."
    envvar_fail=1
fi

if [ -z "$PGHOST" ]; then
    echo "ERROR: PGHOST is not set."
    envvar_fail=1
fi

if [ -z "$PGUSER" ]; then
    echo "ERROR: PGUSER is not set."
    envvar_fail=1
fi

if [ -z "$WORKINGSPACEPATH" ]; then
    echo "ERROR: WORKINGSPACEPATH is not set."
    envvar_fail=1
fi

if [ -n "$envvar_fail" ]; then
    echo "One or more required envvars are not set."
    echo "Please set these envvars and try again."
    exit 1
fi

# Now let's checks files and paths before we start copying

fds_loader_zip_source="$FDS_LOADER_SOURCE_PATH/$FDS_LOADER_ZIP_FILENAME"
fds_loader_zip_destination="$FDS_LOADER_PATH/$FDS_LOADER_ZIP_FILENAME"
config_template="/usr/local/etc/config-template.xml"

if [ ! -f "$fds_loader_zip_source" ]; then
  echo "ERROR: file $fds_loader_zip_source does not exist."
  file_fail=1
fi

if [ ! -d "$FDS_LOADER_PATH" ]; then
  echo "ERROR: directory $FDS_LOADER_PATH does not exist."
  file_fail=1
fi

if [ ! -f "$config_template" ]; then
  echo "ERROR: file $config_template does not exist."
  file_fail=1
fi

if [ -n "$file_fail" ]; then
  echo "One or more required files or directories do not exist."
  exit 1
fi

echo "INFO: unzipping FDSLoader"

# Now let's copy the files
cp "$fds_loader_zip_source" "$fds_loader_zip_destination"
unzip -q -o "$fds_loader_zip_destination" -d "$FDS_LOADER_PATH"

echo "INFO: Preparing config file"
fds_loader_binary="$FDS_LOADER_PATH/FDSLoader64" 
key_file="$FDS_LOADER_PATH/key.txt"
config_file="$FDS_LOADER_PATH/config.xml"


# Using pipe rather than slash for sed separator, because some of the
# substitutions are paths
sed \
  -e "s|{DATABASE_NAME}|$PGDATABASE|g" \
  -e "s|{DATABASE_SERVER}|$PGHOST|g" \
  -e "s|{DATABASE_USER}|$PGUSER|g" \
  -e "s|{DOWNLOAD_BASEDIR}|$WORKINGSPACEPATH|g" \
  -e "s|{FACTSET_SERIAL}|$FACTSET_SERIAL|g" \
  -e "s|{FACTSET_USER}|$FACTSET_USER|g" \
  -e "s|{LOCAL_BASEDIR}|$FDS_LOADER_PATH|g" \
  -e "s|{MAX_PARALLEL_LIMIT}|$MACHINE_CORES|g" \
  "$config_template" > "$config_file"

echo "INFO: Updating config with database password"
$fds_loader_binary --update-password --instance db --pwd $PGPASSWORD

echo "INFO: Symlinking key.txt"
ln -sF "$FDS_LOADER_SOURCE_PATH/key.txt" "$key_file"

echo "INFO: checking expected files"

if [ ! -x "$fds_loader_binary" ]; then
  echo "ERROR: FDSLoader binary not found at $fds_loader_binary or is not executable."
  expected_fail=1
fi

if [ ! -f "$key_file" ]; then
  echo "ERROR: Key file not found at $key_file"
  expected_fail=1
fi

if [ ! -f "$config_file" ]; then
  echo "ERROR: Config file not found at $config_file"
  expected_fail=1
fi

if [ -n "$expected_fail" ]; then
  echo "One or more required files or directories do not exist."
  exit 1
fi

echo "INFO: FDSLoader setup and configured."
