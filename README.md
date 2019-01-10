##Script for run vault with Docker

STEP 1 - CONFIGURATION
    
    - Create a docker volume and put it vault.hcl config file 

STEP 2 - LAUNCH
    
    - Launch a single Consul agent. In production, we'd want to have a cluster of 3 or 5 agents as a single node can lead to data loss.
    - Our Vault instance can now use Consul to store the data. All data stored within Consul will be encrypted.
STEP 3 - INITIALISE

    - This command will create an alias which will proxy commands to vault to the Docker container. 
      As we're in development, we need to define a non-HTTPS address for the vault
    - With the alias in place, we can make calls to the CLI. The first step is to initialise the vault using the init command.
    
STEP 4 - UNSEAL VAULT

    - When a Vault server is started, it starts in a sealed state. 
    - The server knows how to communicate with the backend storage, but it does not know how to decrypt any of the contents
    - Vault uses an algorithm known as Shamir's Secret Sharing to split the master key into shards.

STEP 5 - VAULT TOKENS

    - Tokens are used to communicate with the Vault. When the vault was initialised, a root token was outputted. 
    - Store this in a variable with the following command. We'll use it for future API calls.

STEP 6 - READ/WRITE DATA

    - The Vault CLI can be used to read and write data securely. Vault is a primarily a key/value store.
    
STEP 7 - HTTP API

    - You can also use the HTTP API to obtain the same data. Using a Vault Token, we can access our keys and have JSON returned.
    - Using the command like tool jq we can parse the data and extract the value for our key

STEP 8 - CONSUL DATA

    - As Vault stores all the data as encrypted key/values in Consul you can use the Consul UI to see the encrypted data.
    - You'll be able to see the encrypted string. However, you can only get to the raw data if you have access to Vault and it's unsealed.
      open the browser http://localhost:8500/ui/#/dc1/kv/vault/logical/