from typing import List, Tuple, Set, Dict
import os
from dotenv import load_dotenv
from web3 import Web3, types
import config
import json
from eth_abi import encode

load_dotenv()

w3 = Web3(Web3.HTTPProvider(os.environ['MAINNET_RPC']))


def get_events(contract_address: str, from_block: int) -> List[Dict]:
    return w3.eth.get_logs({
        'fromBlock': from_block,
        'toBlock': 'latest',
        'address': contract_address
    })


def log_events():
    for vault_deploy_data in config.DEPLOY_CONTRACTS_DATA:
        events = []
        for name, data in vault_deploy_data.items():
            contract_address = data['address']
            from_block = int(data['creation_block'])
            contract_events = get_events(contract_address, from_block)
            for log in contract_events:
                event = {
                    "emitter": contract_address,
                    "topics": [topic.hex() for topic in log['topics']],
                    "data": '0x' + ('0' * 128) + log['data'].hex()[2:]
                }
                events.append(event)

        log_file_name = 'events_{}.json'.format(
            vault_deploy_data['Vault']['address']
        ).lower()
        with open('./scripts/mainnet/events_parser/{}'.format(log_file_name), 'w') as f:
            json.dump(events, f)


log_events()
