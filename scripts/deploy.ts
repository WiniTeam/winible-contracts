import { BigNumber } from "ethers";
import { ethers } from "hardhat";

async function main() {

	const [deployer] = await ethers.getSigners();

	const oracle = '0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419';
	const usdc = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48';
	const weth = '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2';


	const Winible = await ethers.getContractFactory("Winible");
	const winible = await Winible.deploy(oracle, usdc, weth, deployer.address);

	await winible.deployed();

	console.log(`Winible deployed to: ${winible.address}`);
	console.log(`Create perks...`);
	await winible.createPerk(0, BigNumber.from(10).mul(BigNumber.from(10).pow(BigNumber.from(6))), '3D Cellar', [2, 3]);
	console.log(`- 3D Cellar... Done`);
}

main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
