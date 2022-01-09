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
const wethAddress = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2';
const routerAddress = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
const dpxAddress = '0x0ff5A8451A839f5F0BB3562689D9A44089738D11';
const fttAddress = '0x50D1c9771902476076eCFc8B2A83Ad6b9355a4c9';
const jewelAddress = '0xd5d86fc8d5c0ea1ac1ac5dfab6e529c9967a45e9';
const shibAddress = '0x28d4a32e275ebb5f16d14ef924281ddcade9a683';
const raiAddress = '0x03ab458634910aad20ef5f1c8ee96f1d6ac54919';

//locals
let beraWrapperAddress = '0x2A97d8f289b0fCcE94107E8237237710EA0b5956';
let beraSwapperAddress = '0x2A97d8f289b0fCcE94107E8237237710EA0b5956';
let twapOracleAddress = '0x7608099153148159af6E36434D28a5fF692929DC';
let swapOracleAddress = '0x1B5424296Ee6cB3b7F7bee7b54EA086B31541ff4';
let beraPoolStandardRiskAddress = '0x53507d389eFE6F354f3065a6DcdD001f3AcF8870';

//load accounts
const unlockedAccount = '0x2feb1512183545f48f6b9c5b4ebfcaf49cfca6f3';
const recipient = '0x461825c82c859CC1C04aE9f1f93f27b2C1C86477';
const privateKey = '0x1178c212eb4d096ab6c20c4ed071ae9d909a1f7517deaf0902dbb510d762a03f';

const account1 = '0x72d58Eb5a1bFA7B9D47Ab47893376Bd4E5Fc762c';
const account2 = '0x8e7EdAc30C16d04b4Eda2E08ADbce32C0e124FB3';
const account3 = '0x20839C0D979b768C8797bC299A74F231f3287a6f';
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
    fttAddress,
    3000, //0.05% pool
    0
).send({from: recipient, to: beraPoolStandardRiskAddress, gas: 6721975});
console.log('Swap Short opened!');

let poolWETHBalance = await wethToken.methods.balanceOf(beraPoolStandardRiskAddress).call();
console.log(poolWETHBalance / 1e18);


}
main();
