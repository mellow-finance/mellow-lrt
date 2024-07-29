# DEPLOYMENTS[chainId][vaultAddress][parameter]

DEPLOYMENTS = {
    1: {},
    17000: {
        # test obol deployment 1
        '0x2d3086b7d3a2a14e121c0fce651f9e1a819a1e84'.lower(): {
            'ManagedValidator': '0xe659ab3de7ca8f6ac4d52a0b7ce0dcaabd07946a'.lower(),
            'VaultConfigurator': '0xa81e199e01350e7d7ee6be846329b20e43eee735'.lower(),
            'ManagedValidatorCreationBlock': 1902723,
            'VaultConfiguratorCreationBlock': 1902723
        },
        # test obol deployment 2
        '0x7F31eb85aBE328EBe6DD07f9cA651a6FE623E69B'.lower(): {
            'ManagedValidator': '0xf02502935f4060D7f7Ebadb95627fAD6912173e1'.lower(),
            'VaultConfigurator': '0x5aab3E3E9D627f2d027808c3780f7d746C8E8138'.lower(),
            'ManagedValidatorCreationBlock': 1986453,
            'VaultConfiguratorCreationBlock': 1986453
        }
    }
}

CHAIN_KEY = {
    1: 'MAINNET_RPC',
    17000: 'HOLESKY_RPC',
}
