//load web3
const Web3 = require('web3');
const web3 = new Web3('ws://localhost:8545');

//load ABIs to interact with contracts
//public ABIs
const wethABI = require('./abi.json');
const daiABI = require('./daiABI.json');
const routerABI = require('./routerAbi.json'); //Uniswap Router

//local contracts
const beraRouterABI = require('./BeraRouter.json');
const beraPoolStandardRiskABI = require('./BeraPoolStandardRisk.json');
const beraWrapperABI = require('./BeraWrapper.json');
const beraPoolABI = require('./BeraPool.json');
const gttABI = require('./GTTAbi.json');

//load contract addresses
//mainnet
const daiAddress = '0x6B175474E89094C44Da98b954EedeAC495271d0F';
const wethAddress = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2';
const routerAddress = "0xE592427A0AEce92De3Edee1F18E0157C05861564";

//locals
const beraWrapperAddress = '0xe90F13095a59C7824f6586F03c4133fdd44d0E86';
const beraPoolStandardRiskAddress = '0xb7eC2f792C6bc242e03dAc3F8c0C9cECb01a914a';
const beraRouterAddress = '0xc7eA80c02E689d092076c21FB6E4471a3638E0ac';

//load accounts
const unlockedAccount = '0x2feb1512183545f48f6b9c5b4ebfcaf49cfca6f3';
const recipient = '0x17541D8a41E29667075DfFC52999f5298fD862e7';
const privateKey = '0xf7e3353111bc3f850e0aef0741ad29feb48bd2e08401923e94d35cb683af3fd0';


//Contract Instances
let beraRouter = new web3.eth.Contract(
  beraRouterABI,
  beraRouterAddress
);

let beraWrapper = new web3.eth.Contract(
  beraWrapperABI,
  beraWrapperAddress
);

let beraPoolStandardRisk = new web3.eth.Contract(
  beraPoolStandardRiskABI,
  beraPoolStandardRiskAddress
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
const allowance = await wethToken.methods.allowance(recipient, routerAddress).call();
console.log(`Router can spend: ${allowance / 1e18} WETH`);

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
//await shortInstance();
//await poolDepositTest();

}



async function shortInstance() {

//approve standardPool to spend DAI
await dai.methods.approve(beraPoolStandardRiskAddress, '1000000000000000000000').send({from: recipient});
await beraPoolStandardRisk.methods.depositCollateral('1000000000000000000000', daiAddress).send({from: recipient, gas: 6721975});
let initialDeposit = await beraPoolStandardRisk.methods.userDepositBalance(recipient).call();
console.log(initialDeposit);
console.log('Deposit Successful');

// //CURRENTLY TESTING: do internal functions require the contract to have gas?
// //the answer is no, the user has to send enough gas to cover both function calls
// // await web3.eth.sendTransaction({
// //   from: recipient,
// //   to: beraPoolStandardRiskAddress,
// //   value: '10000000000000'
// // });
//
// await dai.methods.approve(beraPoolStandardRiskAddress, '1000000000000000000000').send({from: recipient, gas: 238989});
// //first test that users cannot short unless they have deposited funds
// await beraPoolStandardRisk.methods.swapAndShortStandard(
//   '1000000000000000000000',
//   wethAddress,
//   3000,
//   0
// ).send({
//   from: recipient,
//   to: beraPoolStandardRiskAddress,
//   gas: 900000
// });
//
// //check balances to see if short worked as intended
// let userShortBal = await beraPoolStandardRisk.methods.userShortBalance(recipient, 1).call();
// console.log(userShortBal / 1e18);
//
// let poolBalance = await dai.methods.balanceOf(beraPoolStandardRiskAddress).call();
// console.log(poolBalance / 1e18);
//
//
// await beraPoolStandardRisk.methods.closeShortStandardPool(
//   recipient,
//   3,
//   3000
// ).send({
//   from: recipient,
//   gas: 900000
// });
// console.log("Successful Close");
//
// let profits = await beraPoolStandardRisk.methods.userDepositBalance(recipient).call();
// console.log(profits);

}

main();
