const BeraPoolStandardRisk = artifacts.require("BeraPoolStandardRisk");
const BeraWrapper = artifacts.require("BeraWrapper");
const PnLCalculator = artifacts.require("PnLCalculator");
const TWAPOracle = artifacts.require("TWAPOracle");

const swapRouter = '0xE592427A0AEce92De3Edee1F18E0157C05861564';
const USDCETHPool = "0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640";

module.exports = async function(deployer) {
  await deployer.deploy(BeraWrapper);
  const instance = await BeraWrapper.deployed();
  const wrapperAddress = await instance.address;

  await deployer.deploy(PnLCalculator);
  await deployer.link(PnLCalculator, BeraPoolStandardRisk)

  await deployer.deploy(BeraPoolStandardRisk, swapRouter, wrapperAddress);
  const initial = await BeraPoolStandardRisk.deployed();
  const poolAddress = await initial.address;

  await deployer.deploy(TWAPOracle, USDCETHPool, 1, -12);

}
