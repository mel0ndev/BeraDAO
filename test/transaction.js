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
const beraWrapperAddress = '0xe93093f4EceF521283721bEbAAf09724F87128cf';
const beraPoolStandardRiskAddress = '0xa7770660d4709968d4EfdCf5034A9b9a415938EA';
const gttAddress = '0x9c18C71c407cDD5539bF927947D48050FeF0c521';
const beraPoolAddress = '0xec8Fa1F8Ca320324ca271c6351dbbe11fe2B76E7';
const beraRouterAddress = '0xd93239571557593c2229Ea27c98200e8431602f2';

//load accounts
const unlockedAccount = '0x2feb1512183545f48f6b9c5b4ebfcaf49cfca6f3';
const recipient = '0xf03c3D9EE2cAb7cDf1Db432B247Ca32DBF5A2F98';
const privateKey = '0xe2000a79f37670304024c8c2dc3940302041a07fe4482cdf62dab69d4e1863d5';


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

let beraPool = new web3.eth.Contract(
  beraPoolABI,
  beraPoolAddress
);

let gtt = new web3.eth.Contract(
  gttABI,
  gttAddress
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


  // //check that transfer worked
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

}


async function shortInstance() {

//approve bera router to spend DAI
await dai.methods.approve(beraRouterAddress, '1000000000000000000000').send({from: recipient});
let daiAllowance = await dai.methods.allowance(recipient, beraRouterAddress).call();
console.log(`Bera Router can deposit: ${daiAllowance / 1e18} DAI`);

//deposit dai into ecosystem
await beraRouter.methods.depositCollateral('1000000000000000000000', daiAddress).send({
  from: recipient,
  to: beraRouterAddress,
  gas: 600000
});
console.log('Deposit Completed Succesfully!');
let daiBalanaceAfterDeposit = await dai.methods.balanceOf(recipient).call();
console.log(`Recipient Balance after deposit: ${daiBalanaceAfterDeposit / 1e18}`);

//reapprove for transfer function to work properly **********
await dai.methods.approve(beraRouterAddress, '1000000000000000000000').send({from: recipient});
let daiAllowance2 = await dai.methods.allowance(recipient, beraRouterAddress).call();
console.log(`Bera Router can spend: ${daiAllowance2 / 1e18} DAI \n`);

await wethToken.methods.approve(beraPoolStandardRiskAddress, '1000000000000000000').send({from: recipient});

//check pool for debugging
let poolBalance = await dai.methods.balanceOf(beraPoolStandardRiskAddress).call();
console.log(`The Pool initially holds: ${poolBalance / 1e18} DAI`);

//swap dai for weth and >short< weth
//using 50% collateral of 1000 mean 500 dai will get swapped to eth and shorted while 5% of tokens remain as weth
await beraRouter.methods.swapAndShortStandard(
  '1000000000000000000000',
  wethAddress,
  3000,
  0,
  50,
  3330
).send({
  from: recipient,
  to: beraRouterAddress,
  gas: 2000000
});
console.log('Swap and short complete!');

//500 dai should be swapped for eth
//which then sold @ market back for dai,
//capturing a position on chain in an ERC115

//recheck balances to make sure swaps went through
let daiAfterSwap = await dai.methods.balanceOf(recipient).call();
console.log(`Recipient Dai after swap: ${daiAfterSwap / 1e18}`);

//pool balance will be ~500 dai and remaining 5% weth
let poolBalance2 = await wethToken.methods.balanceOf(beraPoolStandardRiskAddress).call();
console.log(`The Pool now holds: ${poolBalance2 / 1e18} WETH for the user`);
console.log('                     &&');

let poolDaiBalance = await dai.methods.balanceOf(beraPoolStandardRiskAddress).call();
console.log(`The Pool has: ${poolDaiBalance / 1e18} DAI remaining`);
console.log('                     &&');

let routerBalance = await dai.methods.balanceOf(beraRouterAddress).call();
console.log(`The Router has: ${routerBalance / 1e18} DAI`)
console.log('                     &&');

//erc1155 details
let id = await beraWrapper.methods.positionID().call();
let position = await beraWrapper.methods.positionData(id - 1).call();
console.log(position);

await wethToken.methods.approve(beraRouterAddress, '10000000000000000000000').send({from: recipient});
await dai.methods.approve(beraRouterAddress, '10000000000000000000000').send({from: recipient});

//reverting because the pool is holding dai and not weth
//have to swap back to weth to close the position for profit/loss
await beraRouter.methods.swapAndCloseShort(
  recipient,
  wethAddress,
  poolDaiBalance,
  3100,
  3000,
  0,
  (id - 1)).send({
  from: recipient,
  to: beraRouterAddress,
  gas: 4000000
});
let userBal = await dai.methods.balanceOf(recipient).call();
console.log(`User Balance after trade: ${userBal / 1e18}`);

let poolBalanceAfterClose = await dai.methods.balanceOf(beraRouterAddress).call();
console.log(`Pool balance after close: ${poolBalanceAfterClose / 1e18}`);

//have to redeploy ABI first***********************
let checkProfits = await beraRouter.methods.userCollateralBalance(recipient).call();
console.log(`Total User collateral: ${checkProfits / 1e18}`);

//it works!!!!
console.log('Success!');


//TODO:
  //check numbers to ensure proper amounts are getting deposited/withdrawn
  //check profit/loss functions
  //adjust how position owner is stored if ERC115 is sent
  //write a loss test
}




main();
