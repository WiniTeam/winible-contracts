import { BigNumber } from "ethers";
import { ethers } from "hardhat";

async function main() {

	const [deployer] = await ethers.getSigners();

	const oracle = '0x89eD62d22945D8Cff271684208B096381F674dBC';
	const usdc = '0x415233609839DB8497f94044734CbcD8D8F46323';
	const weth = '0xb4fbf271143f4fbf7b91a5ded31805e42b2208d6';


	const Winible = await ethers.getContractFactory("Winible");
	const winible = await Winible.deploy(oracle, usdc, weth, deployer.address);

	await winible.deployed();

	console.log(`Winible deployed to: ${winible.address}`);
	console.log(`	> to verify: $ npx hardhat verify --network goerli ${winible.address} ${oracle} ${usdc} ${weth} ${deployer.address}`)

	console.log(`Create perks...`);
	await winible.createPerk(0, BigNumber.from(10).mul(BigNumber.from(10).pow(BigNumber.from(6))), '3D Cellar', [2, 3]);
	console.log(`	> 3D Cellar... Done`);
}

main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
