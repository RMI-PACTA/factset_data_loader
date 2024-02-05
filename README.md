# FactSet Data Loader

## Prerequisites

* Directory to mount to container, containing:
  * FDSLoader download zip (See ["Acquiring Loader Binaries"](#acquiring-loader-binaries) below)
  * `key.txt` (See ["Generating Key"](#generating-key) below)
* Empty directory to use to contain files downloaded from FactSet.
* Postgres Database
  * database named `FDS` (capitalization matters)

> **NOTE:** This container is targeting `FDSLoader64` version `2.13.6.0`

### Environment Variables (envvars)

Environment variable control the behavior of this container.
During local development, these can are via `.env` which docker-compose reads, or set as part of `azure-deploy.json` for cloud deployments.

* `$BYPASS_LOADER`: Set to non-empty string to disable running FDSLoader (restore-only).
* `$DEPLOY_START_TIME`: UTC timestamp used to distinguish exported datasets.
* `$FACTSET_SERIAL`: Serial number for FactSet account, provided by FactSet.
* `$FACTSET_USER`: Username for FactSet account, provided by FactSet.
* `$FDS_LOADER_PATH`: Path in container to `FDSLoader64` application. Default: `/home/fdsrunner`.
* `$FDS_LOADER_SOURCE_PATH`: Path in container to volume mount containing Loader zip file [downloaded from FactSet](#acquiring-loader-binaries) and [`key.txt`](#generating-key). Default: `/mnt/factset-loader`
* `$FDS_LOADER_ZIP_FILENAME`: Name of zip file [downloaded from factset](#acquiring-loader-binaries). Default: `FDSLoader-Linux-2.3.6.0.zip`
* `$MACHINE_CORES`: Integer setting parallelism level for Loader application. Acceptable values: `[1, 2, 4, 8, 16]`. Default: `1`
* `$PGDATABASE`: Database name to load data into. Default `FDS`
* `$PGHOST`: Hostname for PostgreSQL server. Default: `db` for local/docker, `localhost` for Azure deployment.
* `$PGPASSWORD`: Password for PostgreSQL database.
* `$PGUSER`: Username for PostgreSQL superuser
* `$WORKINGSPACEPATH`: Path to empy directory used for downloading data file from FactSet. This path should have available space equal to `16 Gb * $MACHINE_CORES` (suggested by FactSet documentation).
* `$RESTORE_FILE`: filepath to backup file to use as base for restoring database

## Acquiring Loader Binaries

In the [FactSet Resource Library](https://go.factset.com/company/resource-library), find the resource titled "[DataFeed Loader for Linux](https://open.factset.com/api/public/media/download/resources/documents/af0def52-791d-47b9-9147-efe2c02e9f60/FDSLoader-Linux-2.13.6.0.zip)".
Note that this resource requires you to log in with your FactSet ID before downloading.

You may also find it useful to have a copy of the [DataFeed Loader User Guide](https://open.factset.com/api/public/media/download/resources/documents/542ad4eb-4d38-4b0e-b8af-0892289bc67b/DataFeed%20Loader%20User%20Guide%202.13.6.0.zip) and [DataFeed Loader resources](https://open.factset.com/api/public/media/download/resources/documents/4bd1a761-05e3-425f-8813-4f3b6c3c6a7f/resources.zip) (also require login before downloading)

## Generating key

Create key at: [https://auth-setup.factset.com/](https://auth-setup.factset.com/)
and copy contents to `key.txt` in the same directory as the `FDSLoader64` executable.

1. Log in to page (including MFA)
2. Enter Serial number for account
3. Select "PROD" radio select (not "BETA")
4. Check "Legacy" checkbox.

Example:

```text
KeyId: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
Key: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
Counter: 0000000000000000001
```

**Place `key.txt` in the same directory as the `FDSLoader64` executable.**

## Build

```sh
# login to docker registry
az acr login -n transitionmonitordockerregistry
# build image
docker build . -t transitionmonitordockerregistry.azurecr.io/factset_data_loader
# push to registry
docker push transitionmonitordockerregistry.azurecr.io/factset_data_loader:latest
```

## Deploy

```sh
# replace these values with storage account name and resource group appropriate to your deployment
ACI_PERS_STORAGE_ACCOUNT_NAME="pactadata"
ACI_PERS_RESOURCE_GROUP="pacta-data"

STORAGE_KEY=$(az storage account keys list --resource-group "$ACI_PERS_RESOURCE_GROUP" --account-name "$ACI_PERS_STORAGE_ACCOUNT_NAME" --query "[0].value" --output tsv)
echo "$STORAGE_KEY"
```

```sh
# change this value as needed.
RESOURCEGROUP="myResourceGroup"

# run from repo root

az deployment group create --resource-group "$RESOURCEGROUP" --template-file azure-deploy.json --parameters @azure-deploy.parameters.json

```

### Tailing logs

```sh
az container logs --resource-group "$RESOURCEGROUP" --name <CONTAINER GROUP NAME> --container-name loader-runner --follow
```

### Debugging

```sh

az container exec --name "<CONTAINER GROUP NAME>" --container-name loader-runner --resource-group $RESOURCEGROUP --exec-command "/bin/bash"

```

To start a long-running process (to allow for attaching and debugging), add this to `properties` for the container:

```json
  "command": [
    "tail", "-f", "/dev/null"
  ]
```
