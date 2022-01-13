//load web3
const Web3 = require('web3');
const web3 = new Web3('ws://127.0.0.1:8545');

//load ABIs to interact with contracts
//public ABIs
const wethABI = require('./abi.json');
const daiABI = require('./daiABI.json');
const routerABI = require('./routerAbi.json'); //Uniswap Router

//local contracts
const beraPoolStandardRiskABI = require('./BeraPoolStandardRisk.json');
const beraWrapperABI = require('./BeraWrapper.json');
const beraSwapperABI = require('./beraSwapperABI.json');
const oracleABI = require('./oracleABI.json');
const swapOracleABI = require('./swapOracleABI.json');

//load contract addresses
//mainnet
const daiAddress = '0x6B175474E89094C44Da98b954EedeAC495271d0F';
const wethAddress = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'; //has dai pool
const routerAddress = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
const fttAddress = '0x50D1c9771902476076eCFc8B2A83Ad6b9355a4c9'; //has dai no pool
const raiAddress = '0x03ab458634910aad20ef5f1c8ee96f1d6ac54919'; //has dai pool
const usdcAddress = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';
const keepAddress = '0x85Eee30c52B0b379b046Fb0F85F4f3Dc3009aFEC';
const shibAddress = '0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE'; //0.3% SHIB/WETH pool
const kp3rAddress = '0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44' //1% K3PR/WETH pool
const uniAddress = '0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984'; //0.3% UNI/WETH pool
const ringAddress = '0x3b94440C8c4F69D5C9F47BaB9C5A93064Df460F5'; //0.3% RING/WETH pool

//locals
let beraWrapperAddress = '0x1a79d3B3e90Cf163e523442C9DAC3E8b016FA3b7';
let twapOracleAddress = '0x4E940a1874E6b71E2eE88705b2cBC1367D8DeD9c';
let swapOracleAddress = '0x5706DB3a8E67CbB4ed7e84C05657c1C41cf66507';
let beraSwapperAddress = '0x50b5Ce789C946ADA50cE12B537c7395CF5280F76';
let beraPoolStandardRiskAddress = '0x43c01c530ea6f1891b5Cf5517E49989836e522A5';

//load accounts
//truffle test accounts so they change every time incl. private key
const unlockedAccount = '0x2feb1512183545f48f6b9c5b4ebfcaf49cfca6f3';
const recipient = '0xB9eb0c6C166acAaC66CF60220CE9789Ec662d233';
const privateKey = '0xb0178fd5960defe3bb7ef3326a58bab1dba4d9048b9e6ced6ddd3f5bce6a4ffe';

const account1 = '0x9144304b457f1E13A4cfF38bABb87b991D35047D';
const account2 = '0x20db1f0d99AA6FC10a32EaFFdE278D0D7C60288D';
const account3 = '0x737901723D63a3Ee884c1293774aF8db86e28655';
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

let beraSwapper = new web3.eth.Contract(
  beraSwapperABI,
  beraSwapperAddress
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
await oracleTests();
await addUsers();
await shortInstance();
}


async function oracleTests() {

let highRiskCoinPrice = await swapOracle.methods.getSwapPrice(ringAddress, 3000).call();
console.log(highRiskCoinPrice / 1e18);


}

async function addUsers() {

    for (i = 0; i < userArray.length; i++) {
        await dai.methods.approve(beraPoolStandardRiskAddress, '1000000000000000000000').send({from: userArray[i]});
        await beraPoolStandardRisk.methods.depositCollateral('1000000000000000000000').send({from: userArray[i], gas: 6721975});
    }
    console.log('Users added!');
    let poolDaiBalance = await dai.methods.balanceOf(beraPoolStandardRiskAddress).call();
    console.log(poolDaiBalance / 1e18);


}



async function shortInstance() {

//approve standardPool to spend DAI
await dai.methods.approve(beraPoolStandardRiskAddress, '1000000000000000000000').send({from: recipient});
await beraPoolStandardRisk.methods.depositCollateral('1000000000000000000000').send({from: recipient, gas: 6721975});

await dai.methods.approve(beraSwapperAddress, '2000000000000000000000').send({from: recipient});
await beraPoolStandardRisk.methods.swapShort(
    '1000000000000000000000', //1000 dai
    ringAddress, // dai -> weth -> uni
    3000, //0.3% pool
    0
).send({from: recipient, to: beraPoolStandardRiskAddress, gas: 6721975});
console.log('Swap Short opened!');

let posData = await beraWrapper.methods.positionData(4).call();
console.log(posData);

let poolWETHBalance = await wethToken.methods.balanceOf(beraPoolStandardRiskAddress).call();
console.log(poolWETHBalance / 1e18);
let poolDaiBalance = await dai.methods.balanceOf(beraPoolStandardRiskAddress).call();
console.log(poolDaiBalance / 1e18);
let userBalanceAfterSwap = await dai.methods.balanceOf(recipient).call();
console.log(userBalanceAfterSwap / 1e18);


}
main();
