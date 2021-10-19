const BeraRouter = artifacts.require("BeraRouter");
const BeraPoolStandardRisk = artifacts.require("BeraPoolStandardRisk");
const BeraWrapper = artifacts.require("BeraWrapper");
const BeraPool = artifacts.require("BeraPool");
const GTT = artifacts.require("GoblinTownToken");

var swapRouter = '0xE592427A0AEce92De3Edee1F18E0157C05861564';


module.exports = async function(deployer) {
  await deployer.deploy(BeraWrapper);
  const instance = await BeraWrapper.deployed();
  const wrapperAddress = await instance.address;

  await deployer.deploy(BeraPoolStandardRisk, swapRouter, wrapperAddress);
  const initial = await BeraPoolStandardRisk.deployed();
  const poolAddress = await initial.address;

  await deployer.deploy(GTT, '100000000000000000000');
  const gtt = await GTT.deployed();
  const gttAddress = await gtt.address;

  await deployer.deploy(BeraPool, gttAddress);
  const beraPool = await BeraPool.deployed();
  const beraPoolAddress = await beraPool.address;

  await deployer.deploy(BeraRouter, swapRouter, poolAddress, wrapperAddress, beraPoolAddress);

}
