const { ethers, upgrades } = require("hardhat");
const { expect } = require("chai");


const toWei = (value) => web3.utils.toWei(String(value));
const Uniswap = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
const LINK = "0x514910771AF9Ca656af840dff83E8264EcF986CA";
const BALANCER = "0xba100000625a3754423978a60c9317c58a424e3D";
const DAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F";


describe("ToolV2", () => {
    let swapper;
    let swapperV2;
    let admin;
    let alice;
    let bob;
    let random;
    let link;
    let bal;
    let dai;


    before(async () => {
        [admin, alice, bob, random] = await ethers.getSigners();
        const Swapper = await ethers.getContractFactory("ToolV1");
        link = await ethers.getContractAt("IERC20", LINK);
        bal = await ethers.getContractAt("IERC20", BALANCER);
        dai = await ethers.getContractAt("IERC20", DAI);

        swapper = await upgrades.deployProxy(Swapper, [admin.address]);
        await swapper.deployed();
        swapperV2 = await ethers.getContractFactory("ToolV2");
        swapperV2 = await upgrades.upgradeProxy(swapper.address, swapperV2);
    });


    describe("Swap", () => {
        it("Should fail because it did not send an amount of ETH greater than 0", async () => {
            let errStatus = false
            try {
                await swapperV2.connect(alice)._swapETHToToken([50, 50], [DAI, LINK], {value: toWei("0")});
            } catch(e) {
                assert(e.toString().includes('Not enough ETH'));
                errStatus = true;
            }
            assert(errStatus, 'Did not make a mistake when the user entered 0 as the amount of Ethers to be sent.')
        });


        it("Should not perform the operation if the sum of the percentages is greater than 100", async () => {
            let errStatus = false
            try {
                await swapperV2.connect(alice)._swapETHToToken([60, 50], [DAI, LINK], {value: toWei("1")});
            } catch(e) {
                assert(e.toString().includes('Invalid percentage'));
                errStatus = true;
            }
            assert(errStatus, 'Did not make a mistake when the user entered an incorrect percentage')
        });


        it("Should not perform the operation if the sum of the percentages is less than 100", async () => {
            let errStatus = false
            try {
                await swapperV2.connect(alice)._swapETHToToken([0, 0], [DAI, LINK], {value: toWei("1")});
            } catch(e) {
                assert(e.toString().includes('Invalid percentage'));
                errStatus = true;
            }
            assert(errStatus, 'Did not make a mistake when the user entered an incorrect percentage')
        });


        it("Should fail if the number of percentages does not match the number of tokens", async () => {
            let errStatus = false
            try {
                await swapperV2.connect(alice)._swapETHToToken([50, 50], [DAI], {value: toWei("1")});
            } catch(e) {
                assert(e.toString().includes("Data don't match"));
                errStatus = true;
            }
            assert(errStatus, 'Did not make a mistake when the user incorrectly entered the number of tokens and percentages')
        });


        it("Should have a positive balance LINK", async () => {
            const beforeBalance = await link.balanceOf(alice.address);
            await swapperV2.connect(alice)._swapETHToToken([50, 50], [DAI, LINK], {value: toWei("1")});
            const currentBalance = await link.balanceOf(alice.address);
            expect(Number(currentBalance)).to.gt(Number(beforeBalance));
        });


        it("Should have a positive balance DAI", async () => {
            const beforeBalance = await dai.balanceOf(alice.address);
            await swapperV2.connect(alice)._swapETHToToken([50, 50], [LINK, DAI], {value: toWei("1")});
            const currentBalance = await dai.balanceOf(alice.address);
            expect(Number(currentBalance)).to.gt(Number(beforeBalance));
        });


        it("Should have a positive balance BALANCER", async () => {
            const beforeBalance = await bal.balanceOf(alice.address);
            await swapperV2.connect(alice)._swapETHToToken([50, 50], [BALANCER, DAI], {value: toWei("1")});
            const currentBalance = await bal.balanceOf(alice.address);
            expect(Number(currentBalance)).to.gt(Number(beforeBalance));
        });


        it("Should have a positive balance BALANCER and DAI", async () => {
            const beforeBalanceDAI = await dai.balanceOf(bob.address);
            const beforeBalanceBAL = await bal.balanceOf(bob.address);
            await swapperV2.connect(bob)._swapETHToToken([50, 50], [BALANCER, DAI], {value: toWei("1")});
            const currentBalanceDAI = await dai.balanceOf(bob.address);
            const currentBalanceBAL = await bal.balanceOf(bob.address);
            expect(Number(currentBalanceDAI)).to.gt(Number(beforeBalanceDAI));
            expect(Number(currentBalanceBAL)).to.gt(Number(beforeBalanceBAL));
        });


        it("Should have charged a 0.1% fee", async () => {
            const beforeBalance = await admin.getBalance();
            await swapperV2.connect(alice)._swapETHToToken([50, 50], [DAI, BALANCER], {value: toWei("1")});
            const currentBalance = await admin.getBalance();
            expect(Number(currentBalance)).to.gt(Number(beforeBalance));
        });
    });
});