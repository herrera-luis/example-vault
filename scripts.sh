#!/bin/bash
#------------------------------
#STEP 1 - CONFIGURATION
#------------------------------
docker create -v /config --name config busybox
docker cp vault.hcl config:/config/
#------------------------------
#STEP 2 - LAUNCH
#------------------------------
#Launch a single Consul agent. In production, we'd want to have a cluster of 3 or 5 agents as a single node can lead to data loss.
docker run -d --name consul \
    -p 8500:8500 \
    consul:v0.6.4 \
    agent -dev -client=0.0.0.0
#Our Vault instance can now use Consul to store the data. All data stored within Consul will be encrypted.
docker run -d --name vault-dev \
    --link consul:consul \
    -p 8200:8200 \
    --volumes-from config \
    cgswong/vault:0.5.3 server -config=/config/vault.hcl
#------------------------------
#STEP 3 - INITIALISE
#------------------------------
#This command will create an alias which will proxy commands to vault to the Docker container. 
#As we're in development, we need to define a non-HTTPS address for the vault

alias vault='docker exec -it vault-dev vault "$@"'
export VAULT_ADDR=http://127.0.0.1:8200

#With the alias in place, we can make calls to the CLI. 
#The first step is to initialise the vault using the init command.
vault init -address=${VAULT_ADDR} > keys.txt
cat keys.txt #This command is just for show our 5 secrets saved in this file
#------------------------------
#STEP 4 - UNSEAL VAULT
#------------------------------
#When a Vault server is started, it starts in a sealed state. 
#The server knows how to communicate with the backend storage, but it does not know how to decrypt any of the contents
#To unseal with Vault server you need access to three of the five keys defined when the Vault was initialised.
vault unseal -address=${VAULT_ADDR} $(grep 'Key 1:' keys.txt | awk '{print $NF}') #part 1
vault unseal -address=${VAULT_ADDR} $(grep 'Key 2:' keys.txt | awk '{print $NF}') #part 2
vault unseal -address=${VAULT_ADDR} $(grep 'Key 3:' keys.txt | awk '{print $NF}') #part 3 - Now vault is unseal :)
vault status -address=${VAULT_ADDR} #you can view the status of the vault using
#In production, these keys should be stored separately and securely. 
#Vault uses an algorithm known as Shamir's Secret Sharing to split the master key into shards.
#------------------------------
#STEP 5 - VAULT TOKENS
#------------------------------
#Tokens are used to communicate with the Vault. When the vault was initialised, a root token was outputted. 
#Store this in a variable with the following command. We'll use it for future API calls.
export VAULT_TOKEN=$(grep 'Initial Root Token:' keys.txt | awk '{print substr($NF, 1, length($NF)-1)}')
#You can use this token to login to vault.
vault auth -address=${VAULT_ADDR} ${VAULT_TOKEN}
#------------------------------
#STEP 6 - READ/WRITE DATA
#------------------------------
#The Vault CLI can be used to read and write data securely. Vault is a primarily a key/value store.
#Save data
vault write -address=${VAULT_ADDR} secret/api-key value=12345678
#Read data
vault read -address=${VAULT_ADDR} secret/api-key
vault read -address=${VAULT_ADDR} -field=value secret/api-key #get the value of secret using filter -field
#------------------------------
#STEP 7 - HTTP API
#------------------------------
#You can also use the HTTP API to obtain the same data. Using a Vault Token, 
#we can access our keys and have JSON returned.
curl -H "X-Vault-Token:$VAULT_TOKEN" -XGET http://docker:8200/v1/secret/api-key
#Using the command like tool jq we can parse the data and extract the value for our key
curl -s -H "X-Vault-Token:$VAULT_TOKEN" -XGET http://docker:8200/v1/secret/api-key | jq -r .data.value
#------------------------------
#STEP 8 - CONSUL DATA
#------------------------------
#As Vault stores all the data as encrypted key/values in Consul you can use the Consul UI to see the encrypted data.
#You'll be able to see the encrypted string. However, you can only get to the raw data if you have access to Vault and it's unsealed.
#open the browser http://localhost:8500/ui/#/dc1/kv/vault/logical/