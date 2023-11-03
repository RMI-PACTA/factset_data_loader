#! /bin/sh
#
# This script is to set up the DSN for the FactSet Data Loader

echo "INFO: Setting up DSN for FactSet Data Loader"

# it requires some envvars to be set prior to running.
# Let's check those now before we actually do anything

if [ -z "$FDS_LOADER_PATH" ]; then
    echo "ERROR: FDS_LOADER_PATH is not set."
    envvar_fail=1
fi

if [ -z "$PGDATABASE" ]; then
    echo "ERROR: PGDATABASE is not set."
    envvar_fail=1
fi

if [ -z "$PGHOST" ]; then
    echo "ERROR: PGHOST is not set."
    envvar_fail=1
fi

if [ -n "$envvar_fail" ]; then
    echo "One or more required envvars are not set."
    echo "Please set these envvars and try again."
    exit 1
fi

dsn_template="/usr/local/etc/DSN-template.ini"

if [ ! -f "$dsn_template" ]; then
  echo "ERROR: file $dsn_template does not exist."
  file_fail=1
fi

if [ ! -d "$FDS_LOADER_PATH" ]; then
  echo "ERROR: directory $FDS_LOADER_PATH does not exist."
  file_fail=1
fi

if [ -n "$file_fail" ]; then
  echo "One or more required files or directories do not exist."
  exit 1
fi

dsn_destination="$FDS_LOADER_PATH/DSN-FDSLoader.ini"

echo "INFO: Preparing DSN from template $dsn_template"

# Using pipe rather than slash for sed separator, because some of the
# substitutions are paths
sed \
  -e "s|{DATABASE_NAME}|$PGDATABASE|g" \
  -e "s|{DATABASE_SERVER}|$PGHOST|g" \
  "$dsn_template" > "$dsn_destination"

echo "INFO: DSN template configured at $dsn_destination."

echo "INFO: Installing DSN"
odbcinst -i -s -f "$dsn_destination"

echo "INFO: Checking DSN Installation"

odbc_drivers="$(odbcinst -q -s)"
if [ "$odbc_drivers" = "[FDSLoader]" ]; then
    echo "INFO: Correct ODBC Driver found"
elif [ "$odbc_drivers" = "" ]; then
    echo "ERROR: FDSLoader ODBC driver found. Please install ODBC drivers and try again."
    exit 1
fi

echo "INFO: DSN installation complete."

# running wait-for to wait for database to start up before attempting to connect
echo "INFO: Waiting for database port to be available"
# using if ! cmd to test for failure. See: https://www.shellcheck.net/wiki/SC2181
if ! wait-for.sh $PGHOST:5432 -t 120; then
  echo "ERROR: Open port not found at $PGHOST:5432"
  exit 1
fi

echo "INFO: Checking Database connection"

# using if ! cmd to test for failure. See: https://www.shellcheck.net/wiki/SC2181
if ! catalog_names=$(
  echo "SELECT table_catalog, count(*) FROM information_schema.tables GROUP BY table_catalog;" | \
    isql -v -b -d: FDSLoader "$PGUSER" "$PGPASSWORD"
); then
  echo "ERROR: Database connection failed. isql output follows:"
  echo "$catalog_names"
  exit 1
fi

echo "INFO: Database connection confirmed"


