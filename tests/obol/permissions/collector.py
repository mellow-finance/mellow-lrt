from web3 import Web3

from dotenv import load_dotenv

import os
import config
import json

load_dotenv()


STEP = 10000
LOGS_PATH = './tests/obol/permissions/__collector_logs__/'


def parse_events(contract_address, creation_block, to_block):
    contract_address = Web3.toChecksumAddress(contract_address)
    all_data = set()
    for from_block in range(creation_block, to_block + 1, STEP):
        to_block = min(from_block + STEP, to_block)
        logs = w3.eth.get_logs({
            'address': contract_address,
            'fromBlock': from_block,
            'toBlock': to_block
        })
        for log in logs:
            topics = log['topics']
            for topic in topics:
                all_data.add(topic.hex())
            all_data.add(log['data'])
    return all_data


for chain, items in config.DEPLOYMENTS.items():
    if not os.path.exists(LOGS_PATH):
        os.mkdir(LOGS_PATH)

    w3 = Web3(Web3.HTTPProvider(os.getenv(config.CHAIN_KEY[chain])))
    to_block = w3.eth.get_block('latest').number

    for vault_address, contracts in items.items():
        validator_events = parse_events(
            contracts['ManagedValidator'], contracts['ManagedValidatorCreationBlock'], to_block)
        configurator_events = parse_events(
            contracts['VaultConfigurator'], contracts['VaultConfiguratorCreationBlock'], to_block)
        unique_full_data = validator_events | configurator_events

        unique_address_data = set()
        for data in unique_full_data:
            data = data[2:]
            if len(data) == 64:
                unique_address_data.add(data[:40])
                unique_address_data.add(data[-40:])
            else:
                continue
                # for i in range(40, len(data) + 1):
                #     unique_address_data.add(data[i - 40:i])

        unique_address_data.add(contracts['ManagedValidator'][2:].lower())
        unique_address_data.add(contracts['VaultConfigurator'][2:].lower())

        unique_address_data = sorted(list(unique_address_data))
        for i, address in enumerate(unique_address_data):
            unique_address_data[i] = Web3.toChecksumAddress('0x' + address)

        with open('{}{}.json'.format(LOGS_PATH, vault_address), 'w') as f:
            f.write(json.dumps(unique_address_data))
