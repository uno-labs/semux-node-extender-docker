--
-- PostgreSQL database dump
--

-- Dumped from database version 10.12 (Ubuntu 10.12-0ubuntu0.18.04.1)
-- Dumped by pg_dump version 10.12 (Ubuntu 10.12-0ubuntu0.18.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: blockchain; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA blockchain;


--
-- Name: pool_manager; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA pool_manager;


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: addresses_state; Type: TYPE; Schema: blockchain; Owner: -
--

CREATE TYPE blockchain.addresses_state AS ENUM (
    'NOT_DELEGATE',
    'DELEGATE',
    'VALIDATOR'
);


--
-- Name: transaction_internal_type; Type: TYPE; Schema: blockchain; Owner: -
--

CREATE TYPE blockchain.transaction_internal_type AS ENUM (
    'CALL',
    'DELEGATECALL',
    'CALLCODE',
    'CREATE'
);


--
-- Name: transaction_type; Type: TYPE; Schema: blockchain; Owner: -
--

CREATE TYPE blockchain.transaction_type AS ENUM (
    'COINBASE',
    'TRANSFER',
    'DELEGATE',
    'VOTE',
    'UNVOTE',
    'CREATE',
    'CALL'
);


--
-- Name: transaction_state; Type: TYPE; Schema: pool_manager; Owner: -
--

CREATE TYPE pool_manager.transaction_state AS ENUM (
    'NO',
    'PUBLISHED',
    'REJECTED',
    'CONFIRMED'
);


--
-- Name: addresses_before_insert_or_update(); Type: FUNCTION; Schema: blockchain; Owner: -
--

CREATE FUNCTION blockchain.addresses_before_insert_or_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   NEW.data_addr  = decode(NEW.data->>'addr', 'base64');
   NEW.data_state = (NEW.data->>'state')::blockchain.addresses_state;

   IF ((NEW.data->>'delegate_state') is NOT NULL) THEN
   NEW.data_delegate_state_votes_sum = (NEW.data->'delegate_state'->>'votes_sum')::bigint;
   ELSE
   NEW.data_delegate_state_votes_sum = 0;
   END IF;

   RETURN NEW;
END;
$$;


--
-- Name: blocks_before_insert_or_update(); Type: FUNCTION; Schema: blockchain; Owner: -
--

CREATE FUNCTION blockchain.blocks_before_insert_or_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   NEW.data_hash         = decode(NEW.data->>'hash', 'base64');
   NEW.data_forged_by_addr_id = (NEW.data->>'forged_by_addr_id')::bigint;
   RETURN NEW;
END;
$$;


--
-- Name: transactions_before_insert_or_update(); Type: FUNCTION; Schema: blockchain; Owner: -
--

CREATE FUNCTION blockchain.transactions_before_insert_or_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   NEW.data_type         = (NEW.data->>'type')::blockchain.transaction_type;
   NEW.data_block_number = (NEW.data->>'block_number')::bigint;
   NEW.data_hash         = decode(NEW.data->>'hash', 'base64');
   NEW.data_from_addr_id = (NEW.data->>'from_addr_id')::bigint;
   NEW.data_to_addr_id   = (NEW.data->>'to_addr_id')::bigint;
   RETURN NEW;
END;
$$;


--
-- Name: transactions_by_addresses_before_insert_or_update(); Type: FUNCTION; Schema: blockchain; Owner: -
--

CREATE FUNCTION blockchain.transactions_by_addresses_before_insert_or_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   NEW.data_block_number = (NEW.data->>'block_number')::bigint;
   NEW.data_hash         = decode(NEW.data->>'hash', 'base64');
   NEW.data_from_addr_id = (NEW.data->>'from_addr_id')::bigint;
   NEW.data_to_addr_id   = (NEW.data->>'to_addr_id')::bigint;
   RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: addresses; Type: TABLE; Schema: blockchain; Owner: -
--

CREATE TABLE blockchain.addresses (
    id bigint NOT NULL,
    data_version bigint DEFAULT 0 NOT NULL,
    data_model_version bigint DEFAULT 0 NOT NULL,
    data jsonb,
    data_addr bytea NOT NULL,
    data_state blockchain.addresses_state NOT NULL,
    data_delegate_state_votes_sum bigint DEFAULT 0 NOT NULL
);


--
-- Name: blocks; Type: TABLE; Schema: blockchain; Owner: -
--

CREATE TABLE blockchain.blocks (
    id bigint NOT NULL,
    data_version bigint DEFAULT 0 NOT NULL,
    data_model_version bigint DEFAULT 0 NOT NULL,
    data jsonb,
    data_hash bytea NOT NULL,
    data_forged_by_addr_id bigint NOT NULL
);


--
-- Name: config; Type: TABLE; Schema: blockchain; Owner: -
--

CREATE TABLE blockchain.config (
    id bigint NOT NULL,
    data jsonb NOT NULL,
    data_model_version bigint DEFAULT 0 NOT NULL,
    data_version bigint DEFAULT 0 NOT NULL
);


--
-- Name: config_id_seq; Type: SEQUENCE; Schema: blockchain; Owner: -
--

CREATE SEQUENCE blockchain.config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: config_id_seq; Type: SEQUENCE OWNED BY; Schema: blockchain; Owner: -
--

ALTER SEQUENCE blockchain.config_id_seq OWNED BY blockchain.config.id;


--
-- Name: transactions; Type: TABLE; Schema: blockchain; Owner: -
--

CREATE TABLE blockchain.transactions (
    id bigint NOT NULL,
    data_version bigint DEFAULT 0 NOT NULL,
    data_model_version bigint DEFAULT 0 NOT NULL,
    data jsonb,
    data_block_number bigint NOT NULL,
    data_hash bytea NOT NULL,
    data_type blockchain.transaction_type NOT NULL,
    data_from_addr_id bigint NOT NULL,
    data_to_addr_id bigint NOT NULL
);


--
-- Name: transactions_by_addresses; Type: TABLE; Schema: blockchain; Owner: -
--

CREATE TABLE blockchain.transactions_by_addresses (
    id bigint NOT NULL,
    addr_id bigint NOT NULL,
    transaction_id bigint NOT NULL
);


--
-- Name: transactions_by_addresses_id_seq; Type: SEQUENCE; Schema: blockchain; Owner: -
--

CREATE SEQUENCE blockchain.transactions_by_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transactions_by_addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: blockchain; Owner: -
--

ALTER SEQUENCE blockchain.transactions_by_addresses_id_seq OWNED BY blockchain.transactions_by_addresses.id;


--
-- Name: config; Type: TABLE; Schema: pool_manager; Owner: -
--

CREATE TABLE pool_manager.config (
    id bigint NOT NULL,
    data jsonb NOT NULL,
    data_model_version bigint DEFAULT 0 NOT NULL,
    data_version bigint DEFAULT 0 NOT NULL
);


--
-- Name: config_id_seq; Type: SEQUENCE; Schema: pool_manager; Owner: -
--

CREATE SEQUENCE pool_manager.config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: config_id_seq; Type: SEQUENCE OWNED BY; Schema: pool_manager; Owner: -
--

ALTER SEQUENCE pool_manager.config_id_seq OWNED BY pool_manager.config.id;


--
-- Name: reward_payouts; Type: TABLE; Schema: pool_manager; Owner: -
--

CREATE TABLE pool_manager.reward_payouts (
    id bigint NOT NULL,
    reward_range_id bigint NOT NULL,
    reward_sum bigint NOT NULL,
    fee_sum bigint NOT NULL,
    transaction_state pool_manager.transaction_state NOT NULL,
    transaction_hash bytea,
    transaction_id bigint,
    voter_addr_id bigint NOT NULL,
    management_id bigint NOT NULL
);


--
-- Name: reward_payouts_id_seq; Type: SEQUENCE; Schema: pool_manager; Owner: -
--

CREATE SEQUENCE pool_manager.reward_payouts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reward_payouts_id_seq; Type: SEQUENCE OWNED BY; Schema: pool_manager; Owner: -
--

ALTER SEQUENCE pool_manager.reward_payouts_id_seq OWNED BY pool_manager.reward_payouts.id;


--
-- Name: reward_ranges; Type: TABLE; Schema: pool_manager; Owner: -
--

CREATE TABLE pool_manager.reward_ranges (
    id bigint NOT NULL,
    begin_block_id bigint NOT NULL,
    end_block_id bigint NOT NULL,
    reward_sum bigint NOT NULL,
    comission bigint NOT NULL,
    comission_sum bigint NOT NULL,
    votes_min_age bigint NOT NULL,
    management_id bigint NOT NULL
);


--
-- Name: reward_ranges_id_seq; Type: SEQUENCE; Schema: pool_manager; Owner: -
--

CREATE SEQUENCE pool_manager.reward_ranges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reward_ranges_id_seq; Type: SEQUENCE OWNED BY; Schema: pool_manager; Owner: -
--

ALTER SEQUENCE pool_manager.reward_ranges_id_seq OWNED BY pool_manager.reward_ranges.id;


--
-- Name: rewards; Type: TABLE; Schema: pool_manager; Owner: -
--

CREATE TABLE pool_manager.rewards (
    id bigint NOT NULL,
    validator_addr_id bigint NOT NULL,
    coinbase_block_id bigint NOT NULL,
    voter_addr_id bigint NOT NULL,
    votes bigint NOT NULL,
    votes_age bigint NOT NULL,
    reward bigint NOT NULL,
    reward_range_id bigint NOT NULL,
    management_id bigint NOT NULL
);


--
-- Name: rewards_id_seq; Type: SEQUENCE; Schema: pool_manager; Owner: -
--

CREATE SEQUENCE pool_manager.rewards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rewards_id_seq; Type: SEQUENCE OWNED BY; Schema: pool_manager; Owner: -
--

ALTER SEQUENCE pool_manager.rewards_id_seq OWNED BY pool_manager.rewards.id;


--
-- Name: votes; Type: TABLE; Schema: pool_manager; Owner: -
--

CREATE TABLE pool_manager.votes (
    id bigint NOT NULL,
    from_addr_id bigint NOT NULL,
    to_addr_id bigint NOT NULL,
    transaction_id bigint NOT NULL,
    votes bigint NOT NULL,
    blocks_range int8range NOT NULL,
    begin_block_id bigint DEFAULT 0 NOT NULL
);


--
-- Name: votes_id_seq; Type: SEQUENCE; Schema: pool_manager; Owner: -
--

CREATE SEQUENCE pool_manager.votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: votes_id_seq; Type: SEQUENCE OWNED BY; Schema: pool_manager; Owner: -
--

ALTER SEQUENCE pool_manager.votes_id_seq OWNED BY pool_manager.votes.id;


--
-- Name: config id; Type: DEFAULT; Schema: blockchain; Owner: -
--

ALTER TABLE ONLY blockchain.config ALTER COLUMN id SET DEFAULT nextval('blockchain.config_id_seq'::regclass);


--
-- Name: transactions_by_addresses id; Type: DEFAULT; Schema: blockchain; Owner: -
--

ALTER TABLE ONLY blockchain.transactions_by_addresses ALTER COLUMN id SET DEFAULT nextval('blockchain.transactions_by_addresses_id_seq'::regclass);


--
-- Name: config id; Type: DEFAULT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.config ALTER COLUMN id SET DEFAULT nextval('pool_manager.config_id_seq'::regclass);


--
-- Name: reward_payouts id; Type: DEFAULT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.reward_payouts ALTER COLUMN id SET DEFAULT nextval('pool_manager.reward_payouts_id_seq'::regclass);


--
-- Name: reward_ranges id; Type: DEFAULT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.reward_ranges ALTER COLUMN id SET DEFAULT nextval('pool_manager.reward_ranges_id_seq'::regclass);


--
-- Name: rewards id; Type: DEFAULT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.rewards ALTER COLUMN id SET DEFAULT nextval('pool_manager.rewards_id_seq'::regclass);


--
-- Name: votes id; Type: DEFAULT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.votes ALTER COLUMN id SET DEFAULT nextval('pool_manager.votes_id_seq'::regclass);


--
-- Name: addresses addresses_data_addr_key; Type: CONSTRAINT; Schema: blockchain; Owner: -
--

ALTER TABLE ONLY blockchain.addresses
    ADD CONSTRAINT addresses_data_addr_key UNIQUE (data_addr);


--
-- Name: addresses addresses_pkey; Type: CONSTRAINT; Schema: blockchain; Owner: -
--

ALTER TABLE ONLY blockchain.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: blocks blocks_data_hash_key; Type: CONSTRAINT; Schema: blockchain; Owner: -
--

ALTER TABLE ONLY blockchain.blocks
    ADD CONSTRAINT blocks_data_hash_key UNIQUE (data_hash);


--
-- Name: blocks blocks_pkey; Type: CONSTRAINT; Schema: blockchain; Owner: -
--

ALTER TABLE ONLY blockchain.blocks
    ADD CONSTRAINT blocks_pkey PRIMARY KEY (id);


--
-- Name: config config_pkey; Type: CONSTRAINT; Schema: blockchain; Owner: -
--

ALTER TABLE ONLY blockchain.config
    ADD CONSTRAINT config_pkey PRIMARY KEY (id);


--
-- Name: transactions_by_addresses transactions_by_addresses_pkey; Type: CONSTRAINT; Schema: blockchain; Owner: -
--

ALTER TABLE ONLY blockchain.transactions_by_addresses
    ADD CONSTRAINT transactions_by_addresses_pkey PRIMARY KEY (id);


--
-- Name: transactions transactions_data_hash_key; Type: CONSTRAINT; Schema: blockchain; Owner: -
--

ALTER TABLE ONLY blockchain.transactions
    ADD CONSTRAINT transactions_data_hash_key UNIQUE (data_hash);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: blockchain; Owner: -
--

ALTER TABLE ONLY blockchain.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: config config_pkey; Type: CONSTRAINT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.config
    ADD CONSTRAINT config_pkey PRIMARY KEY (id);


--
-- Name: reward_payouts reward_payouts_reward_range_id_voter_addr_id_key; Type: CONSTRAINT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.reward_payouts
    ADD CONSTRAINT reward_payouts_reward_range_id_voter_addr_id_key UNIQUE (reward_range_id, voter_addr_id);


--
-- Name: reward_ranges reward_ranges_pkey; Type: CONSTRAINT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.reward_ranges
    ADD CONSTRAINT reward_ranges_pkey PRIMARY KEY (id);


--
-- Name: rewards rewards_pkey; Type: CONSTRAINT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.rewards
    ADD CONSTRAINT rewards_pkey PRIMARY KEY (id);


--
-- Name: votes votes_pkey; Type: CONSTRAINT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.votes
    ADD CONSTRAINT votes_pkey PRIMARY KEY (id);


--
-- Name: addresses_data_addr_idx; Type: INDEX; Schema: blockchain; Owner: -
--

CREATE INDEX addresses_data_addr_idx ON blockchain.addresses USING hash (data_addr);


--
-- Name: addresses_data_delegate_state_votes_sum_idx; Type: INDEX; Schema: blockchain; Owner: -
--

CREATE INDEX addresses_data_delegate_state_votes_sum_idx ON blockchain.addresses USING btree (data_delegate_state_votes_sum DESC);


--
-- Name: addresses_data_state_idx; Type: INDEX; Schema: blockchain; Owner: -
--

CREATE INDEX addresses_data_state_idx ON blockchain.addresses USING btree (data_state);


--
-- Name: blocks_data_forged_by_addr_id_idx; Type: INDEX; Schema: blockchain; Owner: -
--

CREATE INDEX blocks_data_forged_by_addr_id_idx ON blockchain.blocks USING btree (data_forged_by_addr_id);


--
-- Name: blocks_data_hash_idx; Type: INDEX; Schema: blockchain; Owner: -
--

CREATE INDEX blocks_data_hash_idx ON blockchain.blocks USING hash (data_hash);


--
-- Name: transactions_by_addresses_addr_idx; Type: INDEX; Schema: blockchain; Owner: -
--

CREATE INDEX transactions_by_addresses_addr_idx ON blockchain.transactions_by_addresses USING btree (addr_id);


--
-- Name: transactions_by_addresses_transaction_idx; Type: INDEX; Schema: blockchain; Owner: -
--

CREATE INDEX transactions_by_addresses_transaction_idx ON blockchain.transactions_by_addresses USING btree (transaction_id);


--
-- Name: transactions_data_block_number_idx; Type: INDEX; Schema: blockchain; Owner: -
--

CREATE INDEX transactions_data_block_number_idx ON blockchain.transactions USING btree (data_block_number);


--
-- Name: transactions_data_from_addr_id_idx; Type: INDEX; Schema: blockchain; Owner: -
--

CREATE INDEX transactions_data_from_addr_id_idx ON blockchain.transactions USING btree (data_from_addr_id);


--
-- Name: transactions_data_hash_idx; Type: INDEX; Schema: blockchain; Owner: -
--

CREATE INDEX transactions_data_hash_idx ON blockchain.transactions USING hash (data_hash);


--
-- Name: transactions_data_to_addr_id_idx; Type: INDEX; Schema: blockchain; Owner: -
--

CREATE INDEX transactions_data_to_addr_id_idx ON blockchain.transactions USING btree (data_to_addr_id);


--
-- Name: transactions_data_type_idx; Type: INDEX; Schema: blockchain; Owner: -
--

CREATE INDEX transactions_data_type_idx ON blockchain.transactions USING btree (data_type);


--
-- Name: reward_payouts_management_id_transaction_state_idx; Type: INDEX; Schema: pool_manager; Owner: -
--

CREATE INDEX reward_payouts_management_id_transaction_state_idx ON pool_manager.reward_payouts USING btree (management_id, transaction_state);


--
-- Name: reward_payouts_transaction_state_idx; Type: INDEX; Schema: pool_manager; Owner: -
--

CREATE INDEX reward_payouts_transaction_state_idx ON pool_manager.reward_payouts USING btree (transaction_state);


--
-- Name: reward_ranges_management_id_end_block_id_idx; Type: INDEX; Schema: pool_manager; Owner: -
--

CREATE INDEX reward_ranges_management_id_end_block_id_idx ON pool_manager.reward_ranges USING btree (management_id, end_block_id DESC NULLS LAST);


--
-- Name: rewards_management_id_reward_range_id_idx; Type: INDEX; Schema: pool_manager; Owner: -
--

CREATE INDEX rewards_management_id_reward_range_id_idx ON pool_manager.rewards USING btree (management_id, reward_range_id);


--
-- Name: votes_begin_block_id_idx; Type: INDEX; Schema: pool_manager; Owner: -
--

CREATE INDEX votes_begin_block_id_idx ON pool_manager.votes USING btree (begin_block_id DESC NULLS LAST);


--
-- Name: votes_blocks_range_idx; Type: INDEX; Schema: pool_manager; Owner: -
--

CREATE INDEX votes_blocks_range_idx ON pool_manager.votes USING gist (blocks_range);


--
-- Name: addresses before_insert_or_update; Type: TRIGGER; Schema: blockchain; Owner: -
--

CREATE TRIGGER before_insert_or_update BEFORE INSERT OR UPDATE ON blockchain.addresses FOR EACH ROW EXECUTE PROCEDURE blockchain.addresses_before_insert_or_update();


--
-- Name: blocks before_insert_or_update; Type: TRIGGER; Schema: blockchain; Owner: -
--

CREATE TRIGGER before_insert_or_update BEFORE INSERT OR UPDATE ON blockchain.blocks FOR EACH ROW EXECUTE PROCEDURE blockchain.blocks_before_insert_or_update();


--
-- Name: transactions before_insert_or_update; Type: TRIGGER; Schema: blockchain; Owner: -
--

CREATE TRIGGER before_insert_or_update BEFORE INSERT OR UPDATE ON blockchain.transactions FOR EACH ROW EXECUTE PROCEDURE blockchain.transactions_before_insert_or_update();


--
-- Name: blocks blocks_data_forged_by_addr_id_fkey; Type: FK CONSTRAINT; Schema: blockchain; Owner: -
--

ALTER TABLE ONLY blockchain.blocks
    ADD CONSTRAINT blocks_data_forged_by_addr_id_fkey FOREIGN KEY (data_forged_by_addr_id) REFERENCES blockchain.addresses(id) ON DELETE RESTRICT;


--
-- Name: transactions_by_addresses transactions_by_addresses_addr_id_fkey; Type: FK CONSTRAINT; Schema: blockchain; Owner: -
--

ALTER TABLE ONLY blockchain.transactions_by_addresses
    ADD CONSTRAINT transactions_by_addresses_addr_id_fkey FOREIGN KEY (addr_id) REFERENCES blockchain.addresses(id) ON DELETE RESTRICT;


--
-- Name: transactions_by_addresses transactions_by_addresses_transaction_id_fkey; Type: FK CONSTRAINT; Schema: blockchain; Owner: -
--

ALTER TABLE ONLY blockchain.transactions_by_addresses
    ADD CONSTRAINT transactions_by_addresses_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES blockchain.transactions(id) ON DELETE RESTRICT;


--
-- Name: transactions transactions_data_block_number_fkey; Type: FK CONSTRAINT; Schema: blockchain; Owner: -
--

ALTER TABLE ONLY blockchain.transactions
    ADD CONSTRAINT transactions_data_block_number_fkey FOREIGN KEY (data_block_number) REFERENCES blockchain.blocks(id) ON DELETE RESTRICT;


--
-- Name: transactions transactions_data_from_addr_id_fkey; Type: FK CONSTRAINT; Schema: blockchain; Owner: -
--

ALTER TABLE ONLY blockchain.transactions
    ADD CONSTRAINT transactions_data_from_addr_id_fkey FOREIGN KEY (data_from_addr_id) REFERENCES blockchain.addresses(id) ON DELETE RESTRICT;


--
-- Name: transactions transactions_data_to_addr_id_fkey; Type: FK CONSTRAINT; Schema: blockchain; Owner: -
--

ALTER TABLE ONLY blockchain.transactions
    ADD CONSTRAINT transactions_data_to_addr_id_fkey FOREIGN KEY (data_to_addr_id) REFERENCES blockchain.addresses(id) ON DELETE RESTRICT;


--
-- Name: reward_payouts reward_payouts_management_id_fkey; Type: FK CONSTRAINT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.reward_payouts
    ADD CONSTRAINT reward_payouts_management_id_fkey FOREIGN KEY (management_id) REFERENCES pool_manager.config(id) ON DELETE RESTRICT;


--
-- Name: reward_payouts reward_payouts_reward_range_id_fkey; Type: FK CONSTRAINT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.reward_payouts
    ADD CONSTRAINT reward_payouts_reward_range_id_fkey FOREIGN KEY (reward_range_id) REFERENCES pool_manager.reward_ranges(id) ON DELETE RESTRICT;


--
-- Name: reward_payouts reward_payouts_transaction_id_fkey; Type: FK CONSTRAINT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.reward_payouts
    ADD CONSTRAINT reward_payouts_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES blockchain.transactions(id) ON DELETE RESTRICT;


--
-- Name: reward_payouts reward_payouts_voter_addr_id_fkey; Type: FK CONSTRAINT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.reward_payouts
    ADD CONSTRAINT reward_payouts_voter_addr_id_fkey FOREIGN KEY (voter_addr_id) REFERENCES blockchain.addresses(id) ON DELETE RESTRICT;


--
-- Name: reward_ranges reward_ranges_begin_block_id_fkey; Type: FK CONSTRAINT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.reward_ranges
    ADD CONSTRAINT reward_ranges_begin_block_id_fkey FOREIGN KEY (begin_block_id) REFERENCES blockchain.blocks(id) ON DELETE RESTRICT;


--
-- Name: reward_ranges reward_ranges_end_block_id_fkey; Type: FK CONSTRAINT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.reward_ranges
    ADD CONSTRAINT reward_ranges_end_block_id_fkey FOREIGN KEY (end_block_id) REFERENCES blockchain.blocks(id) ON DELETE RESTRICT;


--
-- Name: reward_ranges reward_ranges_management_id_fkey; Type: FK CONSTRAINT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.reward_ranges
    ADD CONSTRAINT reward_ranges_management_id_fkey FOREIGN KEY (management_id) REFERENCES pool_manager.config(id) ON DELETE RESTRICT;


--
-- Name: rewards rewards_coinbase_block_id_fkey; Type: FK CONSTRAINT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.rewards
    ADD CONSTRAINT rewards_coinbase_block_id_fkey FOREIGN KEY (coinbase_block_id) REFERENCES blockchain.blocks(id) ON DELETE RESTRICT;


--
-- Name: rewards rewards_management_id_fkey; Type: FK CONSTRAINT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.rewards
    ADD CONSTRAINT rewards_management_id_fkey FOREIGN KEY (management_id) REFERENCES pool_manager.config(id) ON DELETE RESTRICT;


--
-- Name: rewards rewards_reward_range_id_fkey; Type: FK CONSTRAINT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.rewards
    ADD CONSTRAINT rewards_reward_range_id_fkey FOREIGN KEY (reward_range_id) REFERENCES pool_manager.reward_ranges(id) ON DELETE RESTRICT;


--
-- Name: rewards rewards_validator_addr_id_fkey; Type: FK CONSTRAINT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.rewards
    ADD CONSTRAINT rewards_validator_addr_id_fkey FOREIGN KEY (validator_addr_id) REFERENCES blockchain.addresses(id) ON DELETE RESTRICT;


--
-- Name: rewards rewards_voter_addr_id_fkey; Type: FK CONSTRAINT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.rewards
    ADD CONSTRAINT rewards_voter_addr_id_fkey FOREIGN KEY (voter_addr_id) REFERENCES blockchain.addresses(id) ON DELETE RESTRICT;


--
-- Name: votes votes_begin_block_id_fkey; Type: FK CONSTRAINT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.votes
    ADD CONSTRAINT votes_begin_block_id_fkey FOREIGN KEY (begin_block_id) REFERENCES blockchain.blocks(id) ON DELETE RESTRICT;


--
-- Name: votes votes_from_addr_id_fkey; Type: FK CONSTRAINT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.votes
    ADD CONSTRAINT votes_from_addr_id_fkey FOREIGN KEY (from_addr_id) REFERENCES blockchain.addresses(id) ON DELETE RESTRICT;


--
-- Name: votes votes_to_addr_id_fkey; Type: FK CONSTRAINT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.votes
    ADD CONSTRAINT votes_to_addr_id_fkey FOREIGN KEY (to_addr_id) REFERENCES blockchain.addresses(id) ON DELETE RESTRICT;


--
-- Name: votes votes_transaction_id_fkey; Type: FK CONSTRAINT; Schema: pool_manager; Owner: -
--

ALTER TABLE ONLY pool_manager.votes
    ADD CONSTRAINT votes_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES blockchain.transactions(id) ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

