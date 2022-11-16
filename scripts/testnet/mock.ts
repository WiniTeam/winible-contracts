import { BigNumber } from "ethers";
import { ethers } from "hardhat";

async function main() {

	const [deployer] = await ethers.getSigners();

	const WinbleUSDC = await ethers.getContractFactory("ERC20");
	const usdc = await WinbleUSDC.deploy("Winible USDC", "WiniUSDC")
	await usdc.deployed();
	console.log(`Winible USDC deployed to: ${usdc.address}`);

	const Oracle = await ethers.getContractFactory("ChainLink");
	const oracle = await Oracle.deploy();
	await oracle.deployed();
	console.log(`Oracle deployed to: ${oracle.address}`);

}

main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
