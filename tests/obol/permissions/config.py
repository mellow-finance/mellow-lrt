# DEPLOYMENTS[chainId][vaultAddress][parameter]

DEPLOYMENTS = {
    1: {},
    17000: {
        # test obol deployment
        '0x2d3086b7d3a2a14e121c0fce651f9e1a819a1e84': {
            'ManagedValidator': '0xe659ab3de7ca8f6ac4d52a0b7ce0dcaabd07946a',
            'VaultConfigurator': '0xa81e199e01350e7d7ee6be846329b20e43eee735',
            'ManagedValidatorCreationBlock': 1902723,
            'VaultConfiguratorCreationBlock': 1902723
        }
    }
}

CHAIN_KEY = {
    1: 'MAINNET_RPC',
    17000: 'HOLESKY_RPC',
}
