import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";
import { arrayify, keccak256, solidityKeccak256, solidityPack } from "ethers/lib/utils";

async function deployProtocol() {
	const [deployer] = await ethers.getSigners();

	const oracleAddress = '0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419';
	// const usdcAddress = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48';
	const wethAddress = '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2';

	const USDC = await ethers.getContractFactory("ERC20");
	const usdc = await USDC.deploy("USDC TEST", "USDC");
	await usdc.deployed();

	const Winible = await ethers.getContractFactory("Winible");
	const winible = await Winible.deploy(oracleAddress, usdc.address, wethAddress, deployer.address);

	await winible.deployed();

	const Oracle = await ethers.getContractFactory("EACAggregatorProxy");
	const oracle = Oracle.attach(oracleAddress);
	
	const WETH = await ethers.getContractFactory("WETH9");
	const weth = WETH.attach(wethAddress);

	const Cellar = await ethers.getContractFactory("Cellar");

	const Dionysos = await ethers.getContractFactory("Dionysos");
	const dionysos = Dionysos.attach(await winible.dionysos());

	return { winible, deployer, oracle, usdc, weth, Cellar, dionysos };
}

describe("Winible", function () {
	
	describe("Cards", function () {
		it("Should have a card level 1: pay in eth", async function () {
			const { winible, deployer, weth } = await loadFixture(deployProtocol);
			const price = await winible.getPriceInETH(await winible.levelPrices(1));
			await winible.build(1, true, {value: price})
			expect(await winible.ownerOf(0)).to.equal(deployer.address);
			expect(await winible.levels(0)).to.equal(BigNumber.from(1));
			expect(await weth.balanceOf(await winible.dionysos())).to.equal(price);
		});

		it("Should have a card level 1: pay in usdc", async function () {
			const { winible, deployer, usdc } = await loadFixture(deployProtocol);
			await usdc.approve(winible.address, BigNumber.from("1000000000").mul(BigNumber.from(10).pow(BigNumber.from(18))))
			await winible.build(1, false, {value: 0})
			expect(await winible.ownerOf(0)).to.equal(deployer.address);
			expect(await winible.levels(0)).to.equal(BigNumber.from(1));
			expect(await usdc.balanceOf(await winible.dionysos())).to.equal(await winible.levelPrices(1));

		});

		it("Should have a card level 2 and 60 cap", async function () {
			const { winible, deployer, weth, Cellar } = await loadFixture(deployProtocol);

			const price2 = await winible.getPriceInETH(await winible.levelPrices(2));
			await winible.build(2, true, {value: price2});

			expect(await winible.levels(0)).to.equal(BigNumber.from(2));
			expect(await weth.balanceOf(await winible.dionysos())).to.equal(price2);

			const cellar = await Cellar.attach(await winible.cellars(0));
			expect(await cellar.capacity()).to.equal(await winible.capacityUpdate(2));
		});

		it("Should have a level max and max cap", async function () {
			const { winible, deployer, weth, Cellar } = await loadFixture(deployProtocol);
			const price1 = await winible.getPriceInETH(await winible.levelPrices(await winible.MAX_LEVEL()));
			await winible.build(await winible.MAX_LEVEL(), true, {value: price1});
			
			expect(await winible.levels(0)).to.equal(await winible.MAX_LEVEL());
			const cellar = await Cellar.attach(await winible.cellars(0));
			expect(await cellar.capacity()).to.equal(ethers.constants.MaxUint256);
		});

		
	});

	describe("Dionysos", function () {
		it("Should be withdrawn", async function () {
			const { winible, deployer, weth, dionysos } = await loadFixture(deployProtocol);
			const amount = BigNumber.from("123456789");
			
			//wrap some eth
			await weth.deposit({value: amount});
			await weth.transfer(dionysos.address, amount);
			expect(await weth.balanceOf(dionysos.address)).to.equal(amount);
			const adminBefore = await weth.balanceOf(deployer.address);

			await dionysos.withdrawAll([weth.address]);
			expect(await weth.balanceOf(dionysos.address)).to.equal(BigNumber.from(0));
			const adminAfter = await weth.balanceOf(deployer.address);

			expect(adminBefore).to.lt(adminAfter);
			expect(amount).to.equal(adminAfter.sub(adminBefore));			
		});

		it("Should not revert: good amount", async function () {
			const { winible, deployer, weth, dionysos } = await loadFixture(deployProtocol);
			
			const data = solidityKeccak256(["string"], ["bleb-abcdefghij"]);
			const amount = 12345;
			const toSign = await dionysos.getMessageHash(0, amount, data)
			const sig = await deployer.signMessage(arrayify(toSign));

			await expect(dionysos.completeOrder(0, amount, data, sig)).to.not.be.reverted;
		});

		it("Should revert: wrong amount", async function () {
			const { winible, deployer, weth, dionysos } = await loadFixture(deployProtocol);
			
			const data = solidityKeccak256(["string"], ["bleb-abcdefghij"]);
			const amount = 12345;
			const toSign = await dionysos.getMessageHash(0, amount, data)
			const sig = await deployer.signMessage(arrayify(toSign));

			await expect(dionysos.completeOrder(0, amount - 1, data, sig)).to.be.reverted;

			
		});
	});

});
