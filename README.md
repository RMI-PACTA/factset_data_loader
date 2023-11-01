# FactSet Data Loader

## Prerequisites

* Directory containing contents of FDSLoader download zip:
  * `FDSLoader64` binary
  * `cacert.pem`
  * `config.xml`
  * `key.txt` (See "Generating Key") below
* Postgres Database
  * database named `FDS` (capitalization matters)

## Acquiring Loader Binaries

In the FactSet Resource Library, find the resource titled "DataFeed Loader for Linux".
Note that this resource requires you to be logged in with your FactSet ID before downloading.

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

## FDSLoader64 Setup

If needed, run `./FDSLoader64 --setup` and respond to the prompts. Running `./FDSLoader64 --setup` again allows you to see you current configuration and alter specific properties.

Below is a listing of running with `--setup` flag a second time, with sensitive information replaced by `<REDACTED>`

```text
Here are details of your configuration. If you would like to change any of these settings, please press the corresponding number and press Enter.

     1. Download Only? No
     2. Database Type: PostgreSQL
     3. Database Name: FDS
     4. Data Source Name (DSN): FDSLoader
     5. Authentication Type: SQL Server
     9. Loader Location: /mnt/factset-loader/FDSLoader
    11. FactSet Username: <REDACTED>
    12. FactSet Serial Number: <REDACTED>
    13. Set Proxy Information
    14. Loader Parallelization Level: Very High
    15. Loader download only location: [Not Set]
    16. Cloud database? Yes
    17. Database Server Name: pacta-factset.postgres.database.azure.com
    18. Database Port Number: 5432
    19. Load executable path: /user/bin/psql
    22. Using Atomic Rebuild: Yes
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
