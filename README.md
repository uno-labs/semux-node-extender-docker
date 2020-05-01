# Semux-node-extender

# Table of contents
1. [Structure of the repository](#structure)
2. [Prerequisites](#prerequisites)
2. [How to install](#howtoinstall)
    1. [Configuration of the "full-node" service](#configfullnode)
    2. [Configuration of the "db" service](#configdb)
    3. [Configuration of the "node-extender" service](#configne)
3. [Starting a Semux-node-extender](#starting)
4. [Updating a Semux-node-extender](#update)

## Structure of the repository <a name="structure"></a>

All parts of the project are set to work with **docker-compose**. That is, running "Semux-node-extender" consists of the following services:

1. ```full-node``` - "Semux Node" service based on the official Semux Core Project - https://github.com/semuxproject/semux-core/releases/tag/v2.1.1
2. ```db``` -  database service based on PostgreSQL server - https://hub.docker.com/_/postgres
3. ```node-extender``` - service "Node extender" developing by UnoLabs team - https://github.com/uno-labs/semux-node-extender

## Prerequisites <a name="prerequisites"></a>

1. Installed docker
    <br>How to install docker on Ubuntu - https://docs.docker.com/install/linux/docker-ce/ubuntu/
    <br>How to install docker on Windows - https://docs.docker.com/docker-for-windows/install/

2. Installed docker-compose
    <br>How to install docker-compose - https://docs.docker.com/compose/install/#install-compose


## How to install <a name="howtoinstall"></a>

First of all clone this repository and go into the project folder
```
git clone https://github.com/uno-labs/semux-node-extender-docker
cd semux-node-extender-docker
```

###  Configuration of the ```full-node``` service <a name="configfullnode"></a>

Main configuration file of the "full-node" service:

```
./full-node/config/semux.properties
```

Edit the configuration file and change the following pair of strings in the ```API``` section:

```
api.username = username
api.password = password
```
That fields are needed for the "node-extender" service. Fill them whatever you like.

Now, there may be two situations - either you have got a wallet already or you have not.

#### a) you haven't got the wallet yet

Then you have to create it. For more information, please visit this website at https://www.semux.org.

Before you run all containers/services together in a general mode, you must perform the initial run of the "full-node" container, in order to set your password for wallet.
For this, follow the steps below.

Set the following access rights of the wallet file in ```./full-node``` directory:

```
chmod 600 wallet.data
```

Start the "full-node" service and setup password (for random password generating you can use the command ```pwgen -Bs 25 3``` ):

```
sudo docker-compose run --rm fullnode
...
Please enter a new password:
Please repeat the new password:
```

Write down or save your password in any keystorage (ex., KeePass).

Your address of the wallet will be shown in the first line right after you repeat the password. Save it too:

```
INFO     SemuxCli         A new account has been created for you: address = e49a5bddf7235e34da48a608dc2ee24bd8e4a4af
```

If the following line appears in your terminal:
```
INFO     SemuxSync        Block [number = 200, view = 0, hash = 32da907fbec0da4c6c50c5b22690ebd81f0b494f6a88a0fd95626c0705391aef, # txs = 0, # votes = 4]
```
then it's all right.

Now you have to stop the "full-node" service . Use ```Ctrl-C``` for it.


#### b) you have got the wallet already and you remember wallet's password

Copy your wallet file ```wallet.data``` to ```./full-node/``` directory and set the following access rights: ```chmod 600 wallet.data```.

In both cases ( **a)** and **b)** ) return to the root folder of the project and insert your password of the wallet to a ```docker-compose.yml``` file:
```
SEMUX_WALLET_PASSWORD: your_password
```

**The first step has done successfully**

###  Configuration of the ```db``` service <a name="configdb"></a>

You have to configure the database.

Set the following fields in the ```docker-compose.yml``` file:
```
POSTGRES_PASSWORD:  password user of database
POSTGRES_USER:      name user of database
POSTGRES_DB:        title of database

FULLNODE_API_USER_NAME:     api.username from ./full-node/config/semux.properties
FULLNODE_API_USER_PASSWORD: api.password from ./full-node/config/semux.properties

PM_VALIDATOR_NAME:      title of your validator
PM_VALIDATOR_COMISSION: commission of a transaction, percentage (0.00-100.00)
PM_POOLS_ADDR:          addresses of validators (see below)
PM_PAYOUT_ADDR:         address of payout wallet. Start it at 0x... and in double quotation marks
PM_START_BLOCK_ID:      block number for beginning payouts (find it on https://semux.top)
PM_PAYMENT_PERIOD:      number of blocks between payouts
PM_TX_FEE:              tax of the transaction, nano SEM (min 0.005 SEM)
PM_MIN_PAYOUT:          minimum payout in a period, nano SEM
PM_VOTES_MIN_AGE:       minimum number of blocks a vote age
```

Setup of the ***PM_POOLS_ADDR*** field:
```
PM_POOLS_ADDR: "\"0x...\",\"0x...\""
```

Set access rights of the ```docker-compose.yml``` file:
```
chmod 600 docker-compose.yml
```

###  Configuration of the ```node-extender``` service <a name="configne"></a>

Here you have to configure parameters of the Node extender.

Change parameters of the field ```connection_str``` in the ```./node-extender/config.json``` file:
```
"connection_str":"dbname=db_name hostaddr=172.20.128.1 port=5432 connect_timeout=5 user=db_user password=db_user_pwd"
```
Where
1. ```dbname``` - your title of database
2. ```user``` -  your user name of database
3. ```password``` - your user password of database

Set access rights of the ```./node-extender/config.json``` file:
```
chmod 600 config.json
```

#### Updating node-extender configuration

If you want to change parameters of the Node extender then get console of the database container:
```
sudo docker exec -it <container name or ID> psql -U <POSTGRES_USER> -d <POSTGRES_DB>
```

You will get a prompt:
```
<POSTGRES_DB>=#
```

The parameters of the Node extender are in the table ```pool_manager.config```.
For seeing it use the request: ```select * from pool_manager.config```.

For change it use the following request:
```
update pool_manager.config set data='{"id": 1, "name": "PM_VALIDATOR_NAME", "tx_fee": PM_TX_FEE, "comission": PM_VALIDATOR_COMISSION*100, "pools_addr": [PM_POOLS_ADDR], "payout_addr": "PM_PAYOUT_ADDR", "votes_min_age": PM_VOTES_MIN_AGE, "minimal_payout": PM_MIN_PAYOUT, "payment_period": PM_PAYMENT_PERIOD, "start_block_id": PM_START_BLOCK_ID}'::jsonb;
```

## Starting a Semux-node-extender <a name="starting"></a>

After you have configured all the parts you can start up them together:

```
sudo docker-compose up -d
```

## Updating a Semux-node-extender <a name="update"></a>

```
cd /path/to/semux-node-extender-docker
git push origin master
sudo docker-compouse stop
sudo docker image rm semux-node-extender
sudo docker-compose up -d
```
