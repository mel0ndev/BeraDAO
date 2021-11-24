<template>
  <v-container>
    <v-row>
    <v-col>
        <v-card dark>
          <v-card-title>
            Your Positions
          </v-card-title>
            <h3 class="subheading">
              -----
            </h3>
      </v-card>
</v-col>
  <v-col>

      <v-card dark>
        <v-card-title>
          Your Available Liquidity
        </v-card-title>
        <h3 class="subheading">
          -----
        </h3>
    </v-card>

</v-col>
<v-col>

    <v-card dark>
      <v-card-title>
        Your APY
      </v-card-title>
      <h3 class="subheading">
        -----
      </h3>
  </v-card>

  </v-col>
</v-row>


<v-row>
  <v-col
  align="center"
  justify="center"
  >
    <v-card dark
    width="85%"
    class="wrapperCard"
    >
      <h1 class="centerTitle">
        Asset Control Center
      </h1>
      <v-row>
        <v-col>

          <v-card
            color="#2a2a2a">
            <h2 class="otherTitle">
              Deposit
            </h2>
            <div class="buttonWrapper">
              <v-btn
                class="defaultButton"
                @click.prevent="depositDialog = true"
                >
                Deposit
              </v-btn>
            </div>
            <span class="subheading">
                Available to deposit: {{getDai}} DAI
            </span>
          </v-card>
        </v-col>


        <v-col>
          <v-card
            color="#2a2a2a">
            <h2 class="otherTitle">
              Withdraw
            </h2>
            <div class="buttonWrapper">
              <v-btn
                class="defaultButton"
                @click.prevent="withdrawDialog = true"
                >
                Withdaw
              </v-btn>
            </div>
            <span class="subheading">
                Available for withdrawl:
            </span>
          </v-card>
        </v-col>
      </v-row>



    </v-card>
  </v-col>
</v-row>


<v-dialog class="dialogBox" v-model="depositDialog" width="60%">
  <DepositDialog />
</v-dialog>

<v-dialog class="dialogBox" v-model="withdrawDialog" width="60%">
  <WithdrawDialog />
</v-dialog>


  </v-container>
</template>


<script>
import DepositDialog from "./DepositDialog.vue";
import WithdrawDialog from "./WithdrawDialog.vue";
import { mapGetters } from "vuex";

import Web3 from 'web3';
const web3 = new Web3('ws://localhost:8545');

import daiABI from "../../../test/daiABI.json";

const daiAddress = '0x6B175474E89094C44Da98b954EedeAC495271d0F';
let dai = new web3.eth.Contract(
  daiABI,
  daiAddress
);

export default {
  name: 'Main',
  components: {
        DepositDialog,
        WithdrawDialog
    },
  data() {
      return {
        depositDialog: false,
        withdrawDialog: false,
        daiBalance: '',
      }
    },
  computed: {
    ...mapGetters('accounts', ['activeAccount']),
    getDai() {
      return this.daiBalance;
    }
  },
  async created() {
    let account = '0x7D8bF1d5aD61873Cd05FbCf4f9D3C3A1F2ec55d3';
    let initial = await dai.methods.balanceOf(account).call();
    this.daiBalance = (initial / 1e18).toFixed(2);
    //ASYNC NOT WORKING
    //Todo: figure out how to get async functions loading for live blockchain data
  }


  }
</script>


<style scoped>

.subheading {
  display: flex;
  justify-content: center;
  color: #939393;
  padding-bottom: 25px;
}

.centerTitle {
  display: flex;
  justify-content: center;
  padding: 25px;
}

.otherTitle {
  display: flex;
  justify-content: center;
  padding: 15px;
  padding-bottom: 75px;

}

.buttonWrapper {
  display: flex;
  justify-content: center;
  padding-bottom: 25px;

}

.defaultButton {
  color: white;
  background-color: #CC2828 !important;
  text-transform: none !important;
}

.wrapperCard {
  padding: 15px;
  padding-bottom: 100px;
}

</style>
