import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import { parseEther } from "ethers/lib/utils";
import { ethers } from "hardhat";
const buildPoseidon = require("circomlibjs").buildPoseidon;
const { poseidonContract } = require("circomlibjs");

async function deployMastermind() {
  const poseidon = await buildPoseidon();
  const F = poseidon.F;
  const PoseidonT6 = await ethers.getContractFactory(
    poseidonContract.generateABI(5),
    poseidonContract.createCode(5)
  );
  const poseidonT6 = await PoseidonT6.deploy();
  await poseidonT6.deployed();

  const Mastermind = await ethers.getContractFactory("Mastermind", {
    libraries: {
      PoseidonT6: poseidonT6.address,
    },
  });
  const mastermind = await Mastermind.deploy(parseEther("10"), 25);
  await mastermind.deployed();
  return mastermind;
}

(async function run() {
  const mastermind = await deployMastermind();
  console.log("mastermind contract has been deployed to " + mastermind.address);
})();
