#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
   INSERT INTO blockchain.config (id, data) VALUES (1, ' {"fullnode_api_url": "http://172.20.128.2", "fullnode_api_port": 5171, "fullnode_api_login": "$FULLNODE_API_USER_NAME", "fullnode_api_password": "$FULLNODE_API_USER_PASSWORD"}'::jsonb);
   INSERT INTO pool_manager.config (id, data) VALUES (1, '{"id": 1, "name": "$NE_VALIDATOR_NAME", "tx_fee": $NE_TX_FEE, "comission": $(( $NE_VALIDATOR_COMISSION*100 )), "pools_addr": [$NE_POOLS_ADDR], "payout_addr": "$NE_PAYOUT_ADDR", "votes_min_age": $NE_VOTES_MIN_AGE, "minimal_payout": $NE_MIN_PAYOUT, "payment_period": $NE_PAYMENT_PERIOD, "start_block_id": $NE_START_BLOCK_ID}'::jsonb);
EOSQL
