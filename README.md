# azure-sai-datahub-cli
Setup datahub cli to interact with data catalog on securiti.ai. 

## Prerequisites
The script needs terraform and azure cli to run.

Create a `terraform.tfvars` file to proivide azure subscription id, existing resource group and other input to the script as shown below. See `var.tf` file for more details. e.g.
```hcl
az_subscription_id = "your-azure-subscription-id"
az_resource_group  = "existing-resource-group-in-azure"
az_name_prefix     = "unique-prefix-to-use-in-resource-names"
X_API_Secret       = "sai api secret"
X_API_Key          = "sai api key"
X_TIDENT           = "sai api tenant"
azpwd              = "some secure password atleast 16 char 3-outof-4 of alpha-num-caps-special"
```

NOTE: These are mac instructions (homebrew). Provided as-is.
```shell
#install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
## install terraform
brew install terraform
## install az cli
brew install azure-cli
$> az login --use-device-code
```

## Running the script and output

Run the script as shown below. This script will create a azure VM and install/connect the Datahub cli to your securiti tenant. The result should be ssh credentials as shown below. Login to the VM via ssh and use datahub cli. 

```shell
$> git clone https://github.com/amitgupta7/azure-sai-datahub-cli.git
$> source tfAlias
$> tf init
$> tfaa
# null_resource.install_dependencies (remote-exec): testing Datahub Installation by connecting to https://dh.app.securiti.ai/api/gms
# null_resource.install_dependencies (remote-exec): {
# null_resource.install_dependencies (remote-exec):   "datasetKey": {
# null_resource.install_dependencies (remote-exec):     "name": "mysql-1",
# null_resource.install_dependencies (remote-exec):     "origin": "PROD",
# null_resource.install_dependencies (remote-exec):     "platform": "urn:li:dataPlatform:mysql"
# null_resource.install_dependencies (remote-exec):   }
# null_resource.install_dependencies (remote-exec): }
# null_resource.install_dependencies: Creation complete after 2m28s [id=2295944877974414921]
#
# Apply complete! Resources: 8 added, 0 changed, 0 destroyed.
#
# Outputs:
#
# ssh_credentials = <<EOT
# ssh azuser@azure-tf-dh-jumpbox.westus2.cloudapp.azure.com 
# with password: #####PASSWORD-REDACTED######
# EOT
## clean-up
$> tfda
```

