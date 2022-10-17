import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";

describe("Winible", function () {
	
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

		return { winible, deployer, oracle, usdc, weth, Cellar };
	}



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

		// it("Should set the right owner", async function () {
		// 	const { lock, owner } = await loadFixture(deployProtocol);

		// 	expect(await lock.owner()).to.equal(owner.address);
		// });

		// it("Should receive and store the funds to lock", async function () {
		// 	const { lock, lockedAmount } = await loadFixture(
		// 		deployProtocol
		// 	);

		// 	expect(await ethers.provider.getBalance(lock.address)).to.equal(
		// 		lockedAmount
		// 	);
		// });

		// it("Should fail if the unlockTime is not in the future", async function () {
		// 	// We don't use the fixture here because we want a different deployment
		// 	const latestTime = await time.latest();
		// 	const Lock = await ethers.getContractFactory("Lock");
		// 	await expect(Lock.deploy(latestTime, { value: 1 })).to.be.revertedWith(
		// 		"Unlock time should be in the future"
		// 	);
		// });
	});

	// describe("Withdrawals", function () {
	// 	describe("Validations", function () {
	// 		it("Should revert with the right error if called too soon", async function () {
	// 			const { lock } = await loadFixture(deployProtocol);

	// 			await expect(lock.withdraw()).to.be.revertedWith(
	// 				"You can't withdraw yet"
	// 			);
	// 		});

	// 		it("Should revert with the right error if called from another account", async function () {
	// 			const { lock, unlockTime, otherAccount } = await loadFixture(
	// 				deployProtocol
	// 			);

	// 			// We can increase the time in Hardhat Network
	// 			await time.increaseTo(unlockTime);

	// 			// We use lock.connect() to send a transaction from another account
	// 			await expect(lock.connect(otherAccount).withdraw()).to.be.revertedWith(
	// 				"You aren't the owner"
	// 			);
	// 		});

	// 		it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
	// 			const { lock, unlockTime } = await loadFixture(
	// 				deployProtocol
	// 			);

	// 			// Transactions are sent using the first signer by default
	// 			await time.increaseTo(unlockTime);

	// 			await expect(lock.withdraw()).not.to.be.reverted;
	// 		});
	// 	});

	// 	describe("Events", function () {
	// 		it("Should emit an event on withdrawals", async function () {
	// 			const { lock, unlockTime, lockedAmount } = await loadFixture(
	// 				deployProtocol
	// 			);

	// 			await time.increaseTo(unlockTime);

	// 			await expect(lock.withdraw())
	// 				.to.emit(lock, "Withdrawal")
	// 				.withArgs(lockedAmount, anyValue); // We accept any value as `when` arg
	// 		});
	// 	});

	// 	describe("Transfers", function () {
	// 		it("Should transfer the funds to the owner", async function () {
	// 			const { lock, unlockTime, lockedAmount, owner } = await loadFixture(
	// 				deployProtocol
	// 			);

	// 			await time.increaseTo(unlockTime);

	// 			await expect(lock.withdraw()).to.changeEtherBalances(
	// 				[owner, lock],
	// 				[lockedAmount, -lockedAmount]
	// 			);
	// 		});
	// 	});
	// });
});
