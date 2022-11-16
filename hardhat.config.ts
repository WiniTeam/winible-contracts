import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from 'dotenv';
import "hardhat-gas-reporter";

dotenv.config()

const config: HardhatUserConfig = {
	solidity: {
		version: "0.8.17",
		settings: {
			optimizer: {
				enabled: true,
				runs: 1
			}
		}
	},
	networks: {
		goerli: {
			url: `https://goerli.infura.io/v3/${process.env.INFURA_KEY}`,
			accounts: [`${process.env.PRIVATE_KEY}`]
		},
		mainnet: {
			url: `https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`,
			accounts: [`${process.env.PRIVATE_KEY}`]
		},
		fork: {
			url: `http://127.0.0.1:8545`,
			accounts: [`${process.env.PRIVATE_KEY}`]
		},
		hardhat: {
			forking: {
				url: `https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`,
			},
		},
	},
	etherscan: {
		apiKey: process.env.ETHERSCAN_KEY
	},
	gasReporter: {
		currency: 'USD',
		token: 'ETH',
		gasPrice: 15,
		enabled: true,
		coinmarketcap: process.env.COINMARKETCAP,
		excludeContracts: ['mock/']
	}
};

export default config;
