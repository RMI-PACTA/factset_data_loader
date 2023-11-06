# FactSet Data Loader

## Prerequisites

* Directory to be mounted to container, containing:
  * FDSLoader download zip (See ["Acquiring Loader Binaries"](#acquiring-loader-binaries) below)
  * `key.txt` (See ["Generating Key"](#generating-key) below)
* Empty directory to be used to contain files downloaded from FactSet.
* Postgres Database
  * database named `FDS` (capitalization matters)

> **NOTE:** This container has been tested with, and is targeting `FDSLoader64` version `2.13.6.0`

### Environment Variables (envvars)

Many behaviors of this container are controlled via environment variables.
During local development, these can be set via `.env` which is read by docker-compose, or set as part of `azure-deploy.json` for cloud deployments.

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
* `$PGPASSWORD_ENCRYPTED`: `$PGPASSWORD` encrypted by `FDSLoader64` application. See [Generating `$PGPASSWORD_ENCRYPTED`](#generating-pgpassword_encrypted) for more instructions.
* `$PGUSER`: Username for PostgreSQL superuser
* `$WORKINGSPACEPATH`: Path to empy directory used for downloading data file from FactSet. This path should have available space approximately to `16 Gb * $MACHINE_CORES`.

## Acquiring Loader Binaries

In the [FactSet Resource Library](https://go.factset.com/company/resource-library), find the resource titled "[DataFeed Loader for Linux](https://open.factset.com/api/public/media/download/resources/documents/af0def52-791d-47b9-9147-efe2c02e9f60/FDSLoader-Linux-2.13.6.0.zip)".
Note that this resource requires you to be logged in with your FactSet ID before downloading.

You may also find it useful to have a copy of the [DataFeed Loader User Guide](https://open.factset.com/api/public/media/download/resources/documents/542ad4eb-4d38-4b0e-b8af-0892289bc67b/DataFeed%20Loader%20User%20Guide%202.13.6.0.zip) and [DataFeed Loader resources](https://open.factset.com/api/public/media/download/resources/documents/4bd1a761-05e3-425f-8813-4f3b6c3c6a7f/resources.zip) (also require login before downloading)

## Generating key

Create key at: [https://auth-setup.factset.com/](https://auth-setup.factset.com/)
and copy contents to `key.txt` in the same directory as the `FDSLoader64` executable.

1. Log in to page (including MFA)
2. Enter Serial number for account
3. Select "PROD" radio select (not "BETA")
4. Ensure "Legacy" checkbox is checked.

Example:

```text
KeyId: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
Key: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
Counter: 0000000000000000001
```

**Place `key.txt` in the same directory as the `FDSLoader64` executable.**

## FDSLoader64 config

The `FDSLoader64` application stores an encrypted version of the password in the `config.xml` files, along with other application settings.
If you already have this value, the container can handle placing it in the config file along with the rest of the settings as part of `prepare_FDSLoader.sh` if it is exposed to the system as an envvar (`$PGPASSWORD_ENCRYPTED`)

### Generating `$PGPASSWORD_ENCRYPTED`

The most straightforward way to generate the encrypted password for insertion into the config file is to setup the `FDSLoader64` appliction, either in the docker container (as in example below) or on your local machine.
Then extract the encrypted password form the config file and store safely elsewhere.

An example of this process via the docker container:

Start the docker container:

```sh
docker-compose run loader-runner bash
```

> **NOTE:** you will need to have the FDSLoader zip file mentioned [above](#acquiring-loader-binaries).
You will also need a complete `.env` file, including a dummy encrypted password (below shows examples from `example.env`).

Then in the container (interactive):

```sh
prepare_FDSLoader.sh # extract FDSLoader.zip
cd $FDS_LOADER_PATH # change to path with FDSLoader
./FDSLoader64 --setup # run setup command
```

This will present a menu:

```text
Here are details of your configuration. If you would like to change any of these settings, please press the corresponding number and press Enter.

     1. Download Only? No
     2. Database Type: PostgreSQL
     3. Database Name: FDS
     4. Data Source Name (DSN): FDSLoader
     5. Authentication Type: SQL Server
     9. Loader Location: /home/fdsrunner
    11. FactSet Username: FOOUSER
    12. FactSet Serial Number: 123456
    13. Set Proxy Information
    14. Loader Parallelization Level: Very Low
    15. Loader download only location: /mnt/workingspace
    16. Cloud database? No
    17. Database Server Name: db
    18. Database Port Number: 5432
    19. Load executable path: /usr/bin/psql
    22. Using Atomic Rebuild: Yes

Enter line number to edit or quit:
```

**Enter `5`** (for Authentication Type), which will bring up a series of prompts.

```text
What is the database User Name? [postgres]:
```

Enter any value you wish here (does not need to be actual username).

```text
Enter the database password (will not be shown on screen):
```

Enter the database password (application accepts copy-paste, if your terminal supports it).

```text
Re-enter the database password (will not be shown on screen):
```

Re-enter the password, and then you are free to enter `quit` (note: `q` is not sufficent) to return the the bash shell.

From here, you can inspect the config file by migrating it out of the container (via mounts) or a simple:

```sh
cat config.xml
```

The relevant xml entry is `<pass>` (simplified config below)

```xml
<data>
  <database>
    <pass>3bf147a8df803c95261f64b154b336ea</pass>
    <user>foo</user>
  </database>
</data>
```

> **NOTE:** The password used to generate this example is `1234`, if you wish to confirm results on your own system.

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

Debugging:

```sh

az container exec --name "<CONTAINER GROUP NAME>" --container-name loader-runner --resource-group $RESOURCEGROUP --exec-command "/bin/bash"

```

To start a long-running process (to allow for attaching and debugging), add this to `properties` for the container:

```json
  "command": [
    "tail", "-f", "/dev/null"
  ]
```
