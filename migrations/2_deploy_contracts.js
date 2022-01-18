const BeraPoolStandardRisk = artifacts.require("BeraPoolStandardRisk");
const BeraWrapper = artifacts.require("BeraWrapper");
const BeraSwapper = artifacts.require("BeraSwapper");
const PnLCalculator = artifacts.require("PnLCalculator");
const TWAPOracle = artifacts.require("TWAPOracle");
const SwapOracle = artifacts.require("SwapOracle");

const swapRouter = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
const USDCETHPool = '0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640';
const factory = '0x1F98431c8aD98523631AE4a59f267346ea31F984';

module.exports = async function(deployer) {
  await deployer.deploy(BeraWrapper);
  const instance = await BeraWrapper.deployed();
  const wrapperAddress = await instance.address;


  await deployer.deploy(PnLCalculator);
  await deployer.link(PnLCalculator, BeraPoolStandardRisk)

  await deployer.deploy(TWAPOracle, factory);
  const oracle = await TWAPOracle.deployed();
  const oracleAddress = await oracle.address;

  await deployer.deploy(SwapOracle, oracleAddress);
  const swapOracle = await SwapOracle.deployed();
  const swapOracleAddress = await swapOracle.address;

  await deployer.deploy(BeraSwapper, swapRouter, oracleAddress, swapOracleAddress);
  const swapperInstance = await BeraSwapper.deployed();
  const swapperAddress = await swapperInstance.address;

  await deployer.deploy(BeraPoolStandardRisk,
      wrapperAddress,
      swapOracleAddress,
      swapperAddress);
  const initial = await BeraPoolStandardRisk.deployed();
  const poolAddress = await initial.address;


}
