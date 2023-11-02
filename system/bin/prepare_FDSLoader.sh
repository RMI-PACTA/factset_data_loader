#! /bin/sh

echo "INFO: Preparing FactSet Data Loader"

# This script is used to prepare the FactSet data loader in a docker container.
# it requires some envvars to be set prior to running.
# Let's check those now before we actually do anything

if [ -z "$FDS_LOADER_SOURCE_PATH" ]; then
    echo "ERROR: FDS_LOADER_SOURCE_PATH is not set."
    envvar_fail=1
fi

if [ -z "$FDS_LOADER_ZIP_FILENAME" ]; then
    echo "ERROR: FDS_LOADER_ZIP_FILENAME is not set."
    envvar_fail=1
fi

if [ -z "$FDS_LOADER_PATH" ]; then
    echo "ERROR: FDS_LOADER_PATH is not set."
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

if [ ! -f "$fds_loader_zip_source" ]; then
  echo "ERROR: file $fds_loader_zip_source does not exist."
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

# Now let's copy the files
cp "$fds_loader_zip_source" "$fds_loader_zip_destination"
unzip -q -o "$fds_loader_zip_destination" -d "$FDS_LOADER_PATH"
