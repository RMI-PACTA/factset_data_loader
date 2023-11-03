#! /bin/sh
# This script is used to run the FactSet data loader in a docker container.

# Install DSN
# This script should be on $PATH (docker should put it as /usr/local/bin/)
setup_DSN.sh

# Copy and unzip FDSLoader Application
# Includes preparing Config file
# This script should be on $PATH (docker should put it as /usr/local/bin/)
prepare_FDSLoader.sh
