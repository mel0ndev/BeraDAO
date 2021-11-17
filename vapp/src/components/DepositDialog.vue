<template>
  <v-card flat
    dark
    class="main"
    >
    <h1 class="heading">
        Deposit
    </h1>

    <v-row>
      <v-col
      justify="center"
      align="center"
      >
        <h2 class="subheading"> Standard Risk Pool Liquidity </h2>
          <div class="circle">
            <div class="innerCircle">
              <span class="middleText"> $1,000,000 </span>
            </div>
          </div>
        <div class="smallTextWrapper">
            <span class="smallText"> APY: 10% </span>
        </div>
      </v-col>


      <v-col
      justify="center"
      align="center"
      >
        <h2 class="subheading"> High Risk Pool Liquidity</h2>
        <div class="circle2">
          <div class="innerCircle2">
            <span class="middleText2"> $1,000,000 </span>
          </div>
        </div>
        <div class="smallTextWrapper">
            <span class="smallText"> APY: 23% </span>
        </div>
      </v-col>
    </v-row>

    <v-row>
      <v-col
      justify="center"
      align="center"
      >

      <div class="switchWrapper">
        <v-switch flat
        @click="changePools"
        :label="`${whatPool}`"
        v-model="boolPool"
        color="red"
        >
        </v-switch>
      </div>

      <div class="buttonWrapper">
          <v-btn @click="submitDeposit" class="defaultButton"> Deposit</v-btn>
      </div>
      </v-col>
    </v-row>


  </v-card>
</template>

<script>
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
name: 'DepositDialog',
computed: {
  ...mapGetters('drizzle', ['drizzleInstance']),
  ...mapGetters('accounts', ['activeAccount']),
},
data() {
  return {
    whatPool: 'Standard Risk',
  }
},
methods: {
  changePools() {
    if (this.boolPool == false) {
      this.whatPool = 'Standard Risk';
    } else {
      (this.boolPool == true)
      this.whatPool = 'High Risk';
    }
  },

  async submitDeposit() {
    await dai.methods.approve('0x85d68F55245aEF21973944a37E1D66a62BE56254', '100000000000000000000').send({from: this.activeAccount});
    await this.drizzleInstance.contracts.BeraRouter.methods.depositCollateral('100000000000000000000', '0x6B175474E89094C44Da98b954EedeAC495271d0F').send();
  }

  }
}
</script>


<style scoped>

.heading {
  display: flex;
  justify-content: center;
  align-items: center;
}

.main {
  padding: 50px;
}

.subheading {
    color: #939393;
    padding-bottom: 25px;
    padding-top: 20px;
}

.circle {
  background-color: #28CCCC;
  border-radius: 50%;
  width: 175px;
  height: 175px;
}

.innerCircle {
  border-radius: 50%;
  background-color: #1E1E1E;
  width: 140px;
  height: 140px;
  position: relative;
  top: 10%;
}


.middleText {
  position: absolute;
  top: 42%;
  left: 23%;
}

.circle2 {
  background-color: #28CC96;
  border-radius: 50%;
  width: 175px;
  height: 175px;
}

.innerCircle2 {
  border-radius: 50%;
  background-color: #1E1E1E;
  width: 140px;
  height: 140px;
  position: relative;
  top: 10%;
}

.middleText2 {
  position: absolute;
  top: 42%;
  left: 23%;
}

.buttonWrapper {
  padding-bottom: 40px;
  padding-top: 10px;
}

.defaultButton {
  color: white;
  background-color: #CC2828 !important;
  text-transform: none !important;
}

.smallTextWrapper {
  padding-top: 25px;
}

.smallText {
    color: #939393;
}

.switchWrapper {
  justify-content: center;
  align-items: center;
  display: flex;
}



</style>
