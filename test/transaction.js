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
const k3prAddress = '0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44' //1% K3PR/WETH pool
const uniAddress = '0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984'; //0.3% UNI/WETH pool

//locals
let beraWrapperAddress = '0x31Bd3dA124d0eA2AbE1871249d26b53A3fDC0AFA';
let twapOracleAddress = '0xf50d856E8F2032557f7c14e599A6a8Ec8a918e82';
let swapOracleAddress = '0x717994B2AEb62f1d24089960E76Cb76Fa7066CC4';
let beraSwapperAddress = '0xC77397D7C5Ce9b5453A332b74392C631301A6e51';
let beraPoolStandardRiskAddress = '0x535C57934555C679FC79Fa958BA1c0fE68BdD616';

//load accounts
const unlockedAccount = '0x2feb1512183545f48f6b9c5b4ebfcaf49cfca6f3';
const recipient = '0x267080c6A28C007739Db8A0B1D3715Ddba23a58D';
const privateKey = '0x6ceaa1e00a1ab2301050f153a73e1bca3b283011505f87ab020508ed87caa686';

const account1 = '0xF5D7503Ba6dc58C7a512A9F81C32ab41A6ada7B4';
const account2 = '0x4fBCcB40678252057d2163baD44f3a18eb3f7De1';
const account3 = '0x4a8c3Fc7bBBd02B2d379496360b7F2eccDb5bc0f';
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
await addUsers();
await shortInstance();
}

async function addUsers() {

    for (i = 0; i < userArray.length; i++) {
        await dai.methods.approve(beraPoolStandardRiskAddress, '1000000000000000000000').send({from: userArray[i]});
        await beraPoolStandardRisk.methods.depositCollateral('1000000000000000000000').send({from: userArray[i], gas: 6721975});
    }
    console.log('Users added!');

}

//TODO fix ABIs for next test

async function shortInstance() {

//approve standardPool to spend DAI
await dai.methods.approve(beraPoolStandardRiskAddress, '1000000000000000000000').send({from: recipient});
await beraPoolStandardRisk.methods.depositCollateral('1000000000000000000000').send({from: recipient, gas: 6721975});

await dai.methods.approve(beraSwapperAddress, '1000000000000000000000').send({from: recipient});
await beraPoolStandardRisk.methods.swapShort(
    '1000000000000000000000', //1000 dai
    usdcAddress, // dai -> weth -> uni
    3000, //0.3% pool
    0
).send({from: recipient, to: beraPoolStandardRiskAddress, gas: 6721975});
console.log('Swap Short opened!');

let poolWETHBalance = await wethToken.methods.balanceOf(beraPoolStandardRiskAddress).call();
console.log(poolWETHBalance / 1e18);


}
main();
