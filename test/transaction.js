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
const beraWrapperAddress = '0x68969724641e2763A6bF66e2a302DDbb892C2509';
const beraPoolStandardRiskAddress = '0x0938900943982b6b2118691801d0ba8dECC9FB3b';
const beraRouterAddress = '0xf4eC8C4d029C0A91472469fB94D2cB4D2bfFaa94';

//load accounts
const unlockedAccount = '0x2feb1512183545f48f6b9c5b4ebfcaf49cfca6f3';
const recipient = '0x4a81F2af22bD4da8a70636E234ea810E99F4eD5f';
const privateKey = '0x91987fe52038dfc19894d26e4d0797e744527e7e7be3b93bacfc3365ec96f38e';

const account1 = '0x682f4bAB635b6D46E13051c8c9fcF003749f486F';
const account2 = '0x02beFEBc7bE9fe2BE33106F662A2C9399c225bCa';
const account3 = '0x7277fBba1d7091f3B4BCdaD114716fA149C6B7E8'
let userArray = [];
userArray.push(account1, account2, account3);


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
//await poolDepositTest();

}



async function shortInstance() {

//approve standardPool to spend DAI
await dai.methods.approve(beraPoolStandardRiskAddress, '1000000000000000000000').send({from: recipient});
await beraPoolStandardRisk.methods.depositCollateral('1000000000000000000000', daiAddress).send({from: recipient, gas: 6721975});
let initialDeposit = await beraPoolStandardRisk.methods.userDepositBalance(recipient).call();
console.log(`Deposit Balance: ${initialDeposit / 1e18}`);
console.log('Deposit Successful');

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

//check balances to see if short worked as intended
let userShortBal = await beraPoolStandardRisk.methods.userShortBalance(recipient, 1).call();
console.log(`Short Balance for position: ${userShortBal / 1e18}`);

let poolBalance = await dai.methods.balanceOf(beraPoolStandardRiskAddress).call();
console.log(`Total Pool Balance: ${poolBalance / 1e18}`);

let entryPrice = await beraPoolStandardRisk.methods.entryPrices(recipient, 1).call();
console.log(`Entry Price at Position 1: ${entryPrice}`);


await beraPoolStandardRisk.methods.closeShortStandardPool(
  recipient,
  1,
  4000, //the price at close
).send({
  from: recipient,
  gas: 900000
});
console.log("Successful Close");

//recheck balance of deposit balance of msg.sender
let profits = await beraPoolStandardRisk.methods.userDepositBalance(recipient).call();
console.log(`Deposit Amount after loss: ${profits / 1e18}`);
console.log('Profits have been added to the account!');

//CURRENT ISSUES:
// deposit amounts in web3 and solidity do not match, missing decimals in one or the other
// and is causing problems with the result on the pnlCalc function

for (j = 0; j < userArray.length; j++) {
  let checkBal = await beraPoolStandardRisk.methods.userDepositBalance(userArray[j]).call();
  console.log(checkBal / 1e18);
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
