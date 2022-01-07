//load web3
const Web3 = require('web3');
const web3 = new Web3('ws://127.0.0.1:8545');

// const contractJson = require('../vapp/src/contracts')
// const contract = require('truffle-contract')
// const testContract = contract(contractJson)
// const ABI = testContract.abi

//load ABIs to interact with contracts
//public ABIs
const wethABI = require('./abi.json');
const daiABI = require('./daiABI.json');
const routerABI = require('./routerAbi.json'); //Uniswap Router

//local contracts
const beraPoolStandardRiskABI = require('./BeraPoolStandardRisk.json');
const beraWrapperABI = require('./BeraWrapper.json');
const beraPoolABI = require('./BeraPool.json');
const oracleABI = require('./oracleABI.json');
const swapOracleABI = require('./swapOracleABI.json');

//load contract addresses
//mainnet
const daiAddress = '0x6B175474E89094C44Da98b954EedeAC495271d0F';
const wethAddress = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2';
const routerAddress = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
const dpxAddress = '0x0ff5A8451A839f5F0BB3562689D9A44089738D11';
const fttAddress = '0x50D1c9771902476076eCFc8B2A83Ad6b9355a4c9';
const jewelAddress = '0xd5d86fc8d5c0ea1ac1ac5dfab6e529c9967a45e9';
const shibAddress = '0x28d4a32e275ebb5f16d14ef924281ddcade9a683';

//locals
let beraWrapperAddress = '0xcBF6F8192b10bBE44498e0B1480B9f275F7E4B4f';
let twapOracleAddress = '0x0C11984667383ce0C874438BD031035B179651Ca';
let swapOracleAddress = '0x066d2A7196e2545ff61CDa0925faE70208a1a724';
let beraPoolStandardRiskAddress = '0x53395E74D07a98B4A4Bd07fC70917fFea168aa03';

//load accounts
const unlockedAccount = '0x2feb1512183545f48f6b9c5b4ebfcaf49cfca6f3';
const recipient = '0x3fb4033a7A2bB248D2414B3540CE28257FDe55aa';
const privateKey = '0xb911aae099efc8a72b90c16f01c20d3a42a0724f5c5cfc2336d8b4d84faaad48';

const account1 = '0x9E0Da84f46DeB90bbaE270331EA3971fE25F73Ee';
const account2 = '0xAeEBcCc9fbf57cb9D7Bc47E661a52380150e4EA6';
const account3 = '0xeb624D0d1d2600dfb15d7D19bD29667af8701C5F';
let userArray = [];
userArray.push(account1, account2, account3);


let beraWrapper = new web3.eth.Contract(
  beraWrapperABI,
  beraWrapperAddress
);

let beraPoolStandardRisk = new web3.eth.Contract(
  beraPoolStandardRiskABI,
  beraPoolStandardRiskAddress
);

let oracle = new web3.eth.Contract(
  oracleABI,
  twapOracleAddress
);

let swapOracle = new web3.eth.Contract(
  swapOracleABI,
  swapOracleAddress
);

let routerContract = new web3.eth.Contract(
  routerABI,
  routerAddress
);

let wethToken = new web3.eth.Contract(
  wethABI,
  wethAddress
);

let dai = new web3.eth.Contract(
  daiABI,
  daiAddress
);

let poolBalance2;
let id;
////////////////////////////////////////////////////////////////////////////////



async function main() {
  let unlockedBalance, recipientBalance;
  let deadline = Math.floor(Date.now() / 1000) + 900;


  ([unlockedBalance, recipientBalance] = await Promise.all([
    wethToken.methods.balanceOf(unlockedAccount).call(),
    wethToken.methods.balanceOf(recipient).call()
  ]))
  let daiBalance = await dai.methods.balanceOf(recipient).call();
  console.log('\n');
  console.log(`Unlocked Wallet: ${unlockedBalance / 1e18} WETH`);
  console.log(`Recipient Wallet: ${recipientBalance / 1e18} WETH`);
  console.log(`Initial Dai Balance: ${daiBalance / 1e18} DAI \n`);


  await wethToken.methods.transfer(recipient, '1000000000000000000').send({from: unlockedAccount});

  for (i = 0; i < userArray.length; i++) {
    await wethToken.methods.transfer(userArray[i], '1000000000000000000').send({from: unlockedAccount});
    await wethToken.methods.approve(routerAddress, '1000000000000000000').send({from: userArray[i]});

    const tokenParams = {
      tokenIn: wethAddress,
      tokenOut: daiAddress,
      fee: 3000,
      recipient: userArray[i],
      deadline: deadline,
      amountIn: '1000000000000000000',
      amountOutMinimum: 0,
      sqrtPriceLimitX96: 0,
  };

    await routerContract.methods.exactInputSingle(tokenParams).send
    ({
      from: userArray[i],
      to: routerAddress,
      gas: 238989
    });
  }

  console.log('Accounts loaded with dai');

  //check that transfer worked
  ([unlockedBalance, recipientBalance] = await Promise.all([
    wethToken.methods.balanceOf(unlockedAccount).call(),
    wethToken.methods.balanceOf(recipient).call()
  ]))
  console.log('///////// AMOUNT AFTER TRANSFER: /////////')
  console.log(`Unlocked Wallet: ${unlockedBalance / 1e18} WETH`);
  console.log(`Recipient Wallet: ${recipientBalance / 1e18} WETH \n`);


  ///////////// swap on uniswap ////////////////////
  const params = {
    tokenIn: wethAddress,
    tokenOut: daiAddress,
    fee: 3000,
    recipient: recipient,
    deadline: deadline,
    amountIn: '1000000000000000000',
    amountOutMinimum: 0,
    sqrtPriceLimitX96: 0,
};

//approve weth spending on uniswap from recipient address
await wethToken.methods.approve(routerAddress, '1000000000000000000').send({from: recipient});

//build transaction so it can be signed and sent over eth netowrk
let tx_builder = await routerContract.methods.exactInputSingle(params);
let encoded_tx = await tx_builder.encodeABI();
let transactionObject = await {
		gas: 238989, // gas fee needs updating?
		data: encoded_tx,
		from: recipient,
		to: routerAddress
	};

  //sign transaction
  await web3.eth.accounts.signTransaction(transactionObject, privateKey, (error, signedTx) => {
  if (error) {
    console.log(error);
  } else {
    web3.eth.sendSignedTransaction(signedTx.rawTransaction).on('receipt', (receipt) => {
      //not loading receipt because it is messy in console but it can be done here if needed
      console.log(`Swap completed! \n`);
    });
  }
});

//check balance after swap to ensure swap occurred
daiBalance = await dai.methods.balanceOf(recipient).call();
console.log(`New Balance: ${daiBalance / 1e18} DAI`);

//call local contracts here in main function
await addUsers();
await shortInstance();
}



async function shortInstance() {

//approve standardPool to spend DAI
await dai.methods.approve(beraPoolStandardRiskAddress, '1000000000000000000000').send({from: recipient});
await beraPoolStandardRisk.methods.depositCollateral('1000000000000000000000', daiAddress).send({from: recipient, gas: 6721975});

let poolAddress = await oracle.methods.getPoolForTWAP(jewelAddress, 10000).call();
console.log(poolAddress);
let ethPrice = await swapOracle.methods.getSwapPrice(wethAddress, 3000).call();

let oracleInitial = await oracle.methods.latestPrice(poolAddress[0]).call();
console.log(oracleInitial * ethPrice / 1e36);

let swapETHPrice = await swapOracle.methods.getSwapPrice(jewelAddress, 10000).call();
console.log(swapETHPrice / 1e36);


await dai.methods.approve(beraPoolStandardRiskAddress, '1000000000000000000000').send({from: recipient, gas: 238989});
//first test that users cannot short unless they have deposited funds
await beraPoolStandardRisk.methods.swapAndShortStandard(
  '1000000000000000000000',
  wethAddress,
  3000, //pool fee
  0
).send({
  from: recipient,
  to: beraPoolStandardRiskAddress,
  gas: 900000
});

//priceAtWrap is passed in at $3000 hard coded into contract for testing right now

let accountStruct = await beraPoolStandardRisk.methods.users(recipient).call();
console.log(accountStruct);

//check balances to see if short worked as intended
let userShortBal = await beraPoolStandardRisk.methods.getUserShortBalance(recipient, 1).call();
console.log(`Short Balance for position: ${userShortBal / 1e18}`);

let poolBalance = await dai.methods.balanceOf(beraPoolStandardRiskAddress).call();
console.log(`Total Pool Balance: ${poolBalance / 1e18}`);

let entryPrice = await beraPoolStandardRisk.methods.getUserEntryPrice(recipient, 1).call();
console.log(`Entry Price at Position 1: ${entryPrice}`);

let positionID = await beraWrapper.methods.positionIDTotal().call();
let positionData = await beraWrapper.methods.positionData(positionID).call();
console.log(positionData);


console.log("Successfully opened a position!");


////////////////////////////////////////////////////////////////////////////////////////////

await beraPoolStandardRisk.methods.closeShortStandardPool(
  recipient,
  1 //user shortID
).send({
  from: recipient,
  gas: 900000
});
console.log("Successful Close");

//recheck balance of deposit balance of msg.sender
let profits = await beraPoolStandardRisk.methods.users(recipient).call();
let realprofits = profits.userDepositBalance;
console.log(`Deposit Amount after loss: ${realprofits / 1e18}`);
console.log('Profits have been added to the account!');

//CURRENT ISSUES:
// deposit amounts in web3 and solidity do not match, missing decimals in one or the other
// and is causing problems with the result on the pnlCalc function

let rewards = await beraPoolStandardRisk.methods.globalRewards().call();
console.log(`The global rewards variable is: ${rewards / 1e18}`);

for (j = 0; j < userArray.length; j++) {
  let checkBal = await beraPoolStandardRisk.methods.users(userArray[j]).call();
    console.log(checkBal.userDepositBalance / 1e18);
  let pullBasedRewards = await beraPoolStandardRisk.methods.checkRewards(userArray[j]).call();
    console.log(`User has: ${pullBasedRewards / 1e18} available to withdraw`);
}

}

async function addUsers() {
  for (i = 0; i < userArray.length; i++) {
    await dai.methods.approve(beraPoolStandardRiskAddress, '1000000000000000000000').send({from: userArray[i]});
    await beraPoolStandardRisk.methods.depositCollateral('1000000000000000000000', daiAddress).send
    ({
      from: userArray[i],
      gas: 6721975
    });
  }
  console.log('Account array done depositing');
}

main();
