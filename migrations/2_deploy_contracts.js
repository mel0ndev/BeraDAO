const BeraPoolStandardRisk = artifacts.require("BeraPoolStandardRisk");
const BeraWrapper = artifacts.require("BeraWrapper");
const PnLCalculator = artifacts.require("PnLCalculator");
const TWAPOracle = artifacts.require("TWAPOracle");

const swapRouter = '0xE592427A0AEce92De3Edee1F18E0157C05861564';
const USDCETHPool = '0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640';
const factory = '0x1F98431c8aD98523631AE4a59f267346ea31F984';

module.exports = async function(deployer) {
  await deployer.deploy(BeraWrapper);
  const instance = await BeraWrapper.deployed();
  const wrapperAddress = await instance.address;

  await deployer.deploy(PnLCalculator);
  await deployer.link(PnLCalculator, BeraPoolStandardRisk)

  await deployer.deploy(TWAPOracle, factory, 1);
  const oracle = await TWAPOracle.deployed();
  const oracleAddress = await oracle.address;

  await deployer.deploy(BeraPoolStandardRisk, swapRouter, wrapperAddress, oracleAddress);
  const initial = await BeraPoolStandardRisk.deployed();
  const poolAddress = await initial.address;


}
