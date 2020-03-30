# Playbooks to Spin Up a Druid Cluster (Imply's Distribution in Azure)


## Prerequisites

The assumption is that you have already completing the following steps:

- Installation of az cli
- az login
- Set up your credentials like so:
```
vi ~/.azure/credentials

[default]
subscription_id=4da4f608-6da0-403a-bc75-0b227d4ca2e9
client_id=de8b0ea9-76bd-4248-95dd-570562bf8c78
secret=180c1e68-484c-469b-885e-7d0d0ae57c0c
tenant=d5c195b1-0472-4244-8f30-4839530dc55b
```
- Create a Service Principal
```
az ad sp create-for-rbac --name ansible_sp

{
  "appId": de8b0ea9-76bd-4248-95dd-990592bf8c78",
  "displayName": "ansible_sp",
  "name": "http://ansible_sp",
  "password": "100e7e61-484c-469b-885e-7d0d0ae57c0c",
  "tenant": "d5c195b1-0472-4244-8f30-4834430dc55b"
}
```
- az login with the Service Principal
```
az login --service-principal --username de8b0ea9-76bd-4248-95dd-990592bf8c78 --password 100e7e61-484c-469b-885e-7d0d0ae57c0c --tenant d5c195b1-0472-4244-8f30-4834430dc55b

```
- Installing Ansible with Azure Python libraries

The vault is leveraged to decrypt the encrypted variables stored unedr **vars/imply/general_vars.yml**. Replace the encrypted and plain text variables with your own by using ansible-vault.
  
### License key

The imply license key can be found under **vars/imply/imply_license_key.yml**. The content is an encrypted format of a licence key following the format below:

```
license_key:
  - name: "pivot-license"
    content: '{"name":"PutYourOrganisationNameHere","expiryDate":"2020-12-31","features":["alerts"]}|2020-03-04|fsdfslnfksdmnfkslmnfklsmndfklsdnfksnvklsnfdklsmnfklsdnmfklsdnmfklsdnfkslngdfksjnfjkdsnfkjsdnfjksdnskjfnsjkfngsjknskdnflksdnmfklsmndflkdsnfksfnddfdfamadeupkeyxxxxxxxxx=='
```

## Running Ansible commands

### Dynamic Inventory

The playbooks leverage dynamic inventories. The file <b>inventory.azure_rm.yml<b> with contents below is provided:
  
```
plugin: azure_rm

include_vm_resource_groups:
  - druid-playground-rg

auth_source: auto

host_key_checking: False

keyed_groups:
  - prefix: tag
    key: tags
  - prefix: loc
    key: location

compose:
  ansible_host: public_ip_address

plain_host_names: yes

```
### Creating the Infrastructure

Running the following command will spin up basic infrastructure to use Imply's distribution of Druid. Of course this a playground, so for convenience sake we leverage public IPs and do not intend to enforce security best practices when spinning up the basic infrastructure. The idea is you that you create and destroy for experimentation purposes only and limit by allowable source IPs and keys.

```
ansible-playbook -i inventory.azure_rm.yml bootstrap_infra.yml --vault-password-file /tmp/password.txt 
```

### Installing Zookeeper

We leverage Confluents Kafka distribution for Zookeeper. 

```
ansible-playbook -i inventory.azure_rm.yml install_zookeeper.yml --vault-password-file /tmp/password.txt
```

### Installing Druid

```
ansible-playbook -i inventory.azure_rm.yml install_imply_druid.yml --vault-password-file /tmp/password.txt --extra-vars "ssl_type=self_signed"
```

### Updating configuration changes

Use the tags to depoy configuration files only. For example to redeploy all druid configurations and restart the processes you can execute:

```
ansible-playbook -i inventory.azure_rm.yml install_imply_druid.yml --vault-password-file /tmp/password.txt  --tags config,deploy_all_configs --extra-vars "ssl_type=self_signed"
```