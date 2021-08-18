const { ethers, upgrades } = require("hardhat");
const { expect } = require("chai");
const { BigNumber } = require("@ethersproject/bignumber");


const toWei = (value) => web3.utils.toWei(String(value));
const Uniswap = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
const LINK = "0x514910771AF9Ca656af840dff83E8264EcF986CA";
const TETHER_USDT = "0xdac17f958d2ee523a2206206994597c13d831ec7";
const DAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F";


describe("ToolV1", () => {
    let swapper;
    let uniswap;
    let weth;
    let admin;
    let alice;
    let bob;
    let random;
    let link;
    let usdt;
    let dai;


    before(async () => {
        [admin, alice, bob, random] = await ethers.getSigners();
        const Swapper = await ethers.getContractFactory("ToolV1");
        uniswap = await ethers.getContractAt("IRouter", Uniswap);
        link = await ethers.getContractAt("IERC20", LINK);
        usdt = await ethers.getContractAt("IERC20", TETHER_USDT);
        dai = await ethers.getContractAt("IERC20", DAI);
        weth = await uniswap.WETH();

        swapper = await Swapper.deploy(admin.address);
        await swapper.deployed();
    });


    describe("Swap", () => {
        it("Should fail because it did not send an amount of ETH greater than 0", async () => {
            let errStatus = false
            try {
                await swapper.connect(alice).swapETHToToken([50, 50], [DAI, LINK], {value: toWei("0")});
            } catch(e) {
                assert(e.toString().includes('Not enough ETH'));
                errStatus = true;
            }
            assert(errStatus, 'Did not make a mistake when the user entered 0 as the amount of Ethers to be sent.')
        });


        it("Should not perform the operation if the sum of the percentages is greater than 100", async () => {
            let errStatus = false
            try {
                await swapper.connect(alice).swapETHToToken([60, 50], [DAI, LINK], {value: toWei("1")});
            } catch(e) {
                assert(e.toString().includes('Invalid percentage'));
                errStatus = true;
            }
            assert(errStatus, 'Did not make a mistake when the user entered an incorrect percentage')
        });


        it("Should not perform the operation if the sum of the percentages is less than 0", async () => {
            let errStatus = false
            try {
                await swapper.connect(alice).swapETHToToken([0, 0], [DAI, LINK], {value: toWei("1")});
            } catch(e) {
                assert(e.toString().includes('Invalid percentage'));
                errStatus = true;
            }
            assert(errStatus, 'Did not make a mistake when the user entered an incorrect percentage')
        });


        it("Should have a positive balance LINK", async () => {
            const beforeBalance = await link.balanceOf(alice.address);
            await swapper.connect(alice).swapETHToToken([50, 50], [DAI, LINK], {value: toWei("1")});
            const currentBalance = await link.balanceOf(alice.address);
            expect(Number(currentBalance)).to.gt(Number(beforeBalance));
        });


        it("Should have a positive balance TETHER", async () => {
            const beforeBalance = await usdt.balanceOf(alice.address);
            await swapper.connect(alice).swapETHToToken([50, 50], [TETHER_USDT, DAI], {value: toWei("1")});
            const currentBalance = await usdt.balanceOf(alice.address);
            expect(Number(currentBalance)).to.gt(Number(beforeBalance));
        });


        it("Should have a positive balance DAI", async () => {
            const beforeBalance = await dai.balanceOf(alice.address);
            await swapper.connect(alice).swapETHToToken([50, 50], [LINK, DAI], {value: toWei("1")});
            const currentBalance = await dai.balanceOf(alice.address);
            expect(Number(currentBalance)).to.gt(Number(beforeBalance));
        });


        it("Should have charged a 0.1% fee", async () => {
            const beforeBalance = await admin.getBalance();
            await swapper.connect(alice).swapETHToToken([50, 50], [DAI, TETHER_USDT], {value: toWei("1")});
            const fee = Number(toWei("1") / 1000);
            const currentBalance = await admin.getBalance();
            expect(Number(currentBalance) - fee).to.equal(Number(beforeBalance));
        });
    });
});