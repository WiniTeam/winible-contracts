import { BigNumber } from "ethers";
import { ethers } from "hardhat";

async function main() {

	const [deployer] = await ethers.getSigners();

	const usdc = '0x415233609839DB8497f94044734CbcD8D8F46323';
	const winibleAddress = '0x9A80A0dA84dbA4e40c746AFAa6B512D277E8A60a';
	const name = 'Chateau Lorem - Winible';
	const ticker = 'Lorem';
	const supply = 10;
	
	const Winible = await ethers.getContractFactory("Winible");
	const winible = await Winible.attach(winibleAddress);

	const Bottle = await ethers.getContractFactory("SampleBottle");
	const bottle = await Bottle.deploy(winible.address, name, ticker, supply, usdc);

	await bottle.deployed();

	console.log(`${name} deployed to: ${bottle.address}`);
	console.log(`	> to verify: $ npx hardhat verify --network goerli ${bottle.address} ${winible.address} "${name}" "${ticker}" ${supply} ${usdc}`);

	await (await winible.setWhitelist(bottle.address, true)).wait();
	console.log(`${name} whitelisted`);
	
}

main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
