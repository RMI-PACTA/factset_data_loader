#! /bin/sh
# This script is used to run the FactSet data loader in a docker container.

#check that ODBC Drivers are installed
odbc_drivers="$(odbcinst -q -s)"
if [ "$odbc_drivers" = "[FDSLoader]" ]; then
    echo "Correct ODBC Driver found"
elif [ "$odbc_drivers" = "" ]; then
    echo "No ODBC drivers found. Please install ODBC drivers and try again."
    exit 1
fi

#establish connection to database
isql -v FDSLoader -U postgres

exit 0
