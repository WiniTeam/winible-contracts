import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from 'dotenv';

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
		ropsten: {
			url: `https://ropsten.infura.io/v3/${process.env.INFURA_KEY}`,
			accounts: [`${process.env.PRIVATE_KEY}`]
		},
		mainnet: {
			url: `https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`,
			accounts: [`${process.env.PRIVATE_KEY}`]
		},
		fork: {
			url: `https://data-seed-prebsc-1-s1.binance.org:8545`,
			accounts: [`${process.env.PRIVATE_KEY}`]
		},

	},
	etherscan: {
		apiKey: process.env.ETHERSCAN_KEY
	}
};

export default config;