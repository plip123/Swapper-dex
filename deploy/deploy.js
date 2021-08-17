const { ethers, upgrades } = require("hardhat");

async function main() {
// Deploying
const ToolV1 = await ethers.getContractFactory("ToolV1");
const instance = await upgrades.deployProxy(ToolV1, ["0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"]);
await instance.deployed();

// Upgrading
const ToolV2 = await ethers.getContractFactory("ToolV2");
const upgraded = await upgrades.upgradeProxy(instance.address, ToolV2);
}

main();
