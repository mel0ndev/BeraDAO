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
const beraWrapperAddress = '0x1093927aD8eDe37de0baD670C82042faB169ecbd';
const beraPoolStandardRiskAddress = '0x858b7Ddb5e4C3774FD60A72B0860a0167ce43b5C';
const beraRouterAddress = '0x2eA081acAcE19e1958f08a563346f7BDC4c4845A';

//load accounts
const unlockedAccount = '0x2feb1512183545f48f6b9c5b4ebfcaf49cfca6f3';
const recipient = '0xDF3E29b62911dCd6F1aEf408a2dd6d72a286c0de';
const privateKey = '0xbb07a314ed4b25c112d183240a17d3d03864695132b58ef451a41c1707c686d3';


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
await shortInstance();
//await poolDepositTest();

}



async function shortInstance() {

//approve standardPool to spend DAI
await dai.methods.approve(beraPoolStandardRiskAddress, '1000000000000000000000').send({from: recipient});
await beraPoolStandardRisk.methods.depositCollateral('1000000000000000000000', daiAddress).send({from: recipient, gas: 238989});
console.log('Deposit Successful');

//CURRENTLY TESTING: do internal functions require the contract to have gas?
//the answer is no, the user has to send enough gas to cover both function calls
// await web3.eth.sendTransaction({
//   from: recipient,
//   to: beraPoolStandardRiskAddress,
//   value: '10000000000000'
// });

await dai.methods.approve(beraPoolStandardRiskAddress, '1000000000000000000000').send({from: recipient, gas: 238989});
//first test that users cannot short unless they have deposited funds
await beraPoolStandardRisk.methods.swapAndShortStandard(
  '1000000000000000000000',
  wethAddress,
  3000,
  0
).send({
  from: recipient,
  to: beraPoolStandardRiskAddress,
  gas: 900000
});

//check balances to see if short worked as intended
let userShortBal = await beraPoolStandardRisk.methods.userShortBalance(recipient, 1).call();
console.log(userShortBal / 1e18);

let poolBalance = await dai.methods.balanceOf(beraPoolStandardRiskAddress).call();
console.log(poolBalance / 1e18); 


await beraPoolStandardRisk.methods.closeShortStandardPool(
  recipient,
  wethAddress,
  '1000000000000000000',
  1,
  4000,
  3000,
  0
).send({
  from: recipient,
  gas: 900000
});
console.log("Successful Close");


}

main();
