import BeraRouter from './contracts/BeraRouter.json'


const options = {
  web3: {
    block: false,
    fallback: {
      type: 'ws',
      url: 'ws://127.0.0.1:8545'
    }
  },
  contracts: [BeraRouter],
  events: {
    //
  },
  polls: {
    accounts: 15000
  }
}

export default options
