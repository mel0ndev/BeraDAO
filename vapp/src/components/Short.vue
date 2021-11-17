<template>
<v-container class="center">
  <v-card dark
    align="center"
    justify="center"
    width="50%"
    class="boxContainer"
    color="#191919">
    <v-card color="#191919"
    flat>
      <div class="titleWrapper">
          <h1> Swap and Short </h1>
      </div>

          <template>
  <v-card
    color="#2a2a2a"
    align="center"
    justify="center"
    dark
    >

      <v-row>
        <v-col
          class="text-left"
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
        </v-col>

          <v-col
            class="text-right"
            >
          <div class="menuWrapper">
          <v-menu
            bottom
            left
            transition="slide-y-transition"

          >

            <template v-slot:activator="{ on, attrs }">
              <v-btn
                icon
                v-bind="attrs"
                v-on="on"
              >
                <v-icon>mdi-dots-vertical</v-icon>
              </v-btn>
            </template>

            <v-list dark>
              <v-list-item>
                <v-list-item-action>
                  <v-icon>mdi-fuel</v-icon>
                </v-list-item-action>
                <v-list-item-content>
                  <v-list-item-title> <b>Gas</b> </v-list-item-title>
                  <v-list-item-content> {{gas}} / ${{usd}} </v-list-item-content>
                </v-list-item-content>
              </v-list-item>
            </v-list>
          </v-menu>
        </div>

        </v-col>
      </v-row>
        <v-row
          class="pa-4"
        >
          <v-col class="text-center">
            <h3 class="text-h5">

            </h3>
            <span class="grey--text text--lighten-1"> </span>
          </v-col>
        </v-row>
    <v-form>
      <v-container>
        <v-row>
          <v-col
            cols="6"
            md="3"
            jusify="center"
            align="center"
          >
          </v-col>
          <v-col
            cols="6"
            dark
            >

            <v-autocomplete
              v-model="value"
              :items="tokens"
              rounded
              solo
              chips
              dark
              flat
              color="red"
              label="Select a token"
              :item-text="tokens"
              :item-value="pools"
            >
            </v-autocomplete>

          </v-col>
        </v-row>
      </v-container>
    </v-form>

    <v-divider></v-divider>

    <div class="denomWrapper">
      <div class="imgWrapper">
        <v-img src="../assets/dai.png"
          width="50px"
          height="50px">
          </v-img>
      </div>
        <h3> Base pair is DAI </h3>
    </div>

    <div class="buttonWrapper">
      <v-btn
        class="shortThePonzi"
        @click.prevent="onSubmit"
        >
        Short This Scam
      </v-btn>
    </div>

  </v-card>
</template>

    </v-card>
    <div class="bottomPadding"> </div>
  </v-card>
</v-container>
</template>

<script>
import axios from 'axios';
import { mapGetters } from 'vuex';

export default {


name: 'Short',

data() {
  return {
    gas: '',
    usd: '',
    tokens: [],
    pools: [],
    value: null,
    whatPool: 'Standard Risk',
    boolPool: false,
  }
},

computed: {
  ...mapGetters('drizzle', ['drizzleInstance']),
  ...mapGetters('accounts', ['activeAcount']),
},

mounted() {

  axios.get('http://ethgas.watch/api/gas')
    .then(res => {
      this.gas = res.data.normal.gwei;
      this.usd = res.data.normal.usd;
    });

    axios.post('https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v3',
  {
    query: `
              {
                  pools(where: {token1: "0x6b175474e89094c44da98b954eedeac495271d0f"}) {
                    id
                    poolDayData(first: 1, orderBy: date, orderDirection: desc) {
                      token0Price
                    }
                    token0 {
                      name
                      id
                    }
                    token1 {
                      name
                      id
              }
            }
          }

        `
  }).then((resp) => {

    var token = resp.data.data.pools
    for (var i = 0; i < token.length; i++) {
        this.tokens.push(token[i].token0.name);
        this.pools.push(token[i].id);
    }

    });
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

    onSubmit() {
      this.drizzleInstance.contracts['BeraRouter'].methods['depositCollateral'].cacheSend(1000, 0xe6cF3B60AFA84f999F9F5c3B551172EFFdE3B321, 0x3dfcc7f20d200dc5b6Dd885b11E77a848dB9f6d6);
    }

  }

}

</script>

<style scoped>

.center {
  display: flex;
  justify-content: center;
}

.switchWrapper {
  display: inline-block;
  padding-left: 15px;
}

.menuWrapper {
  display: inline-block;
  padding-right: 15px;
}

.titleWrapper {
  padding-top: 25px;
  padding-bottom: 50px;
}

.imgWrapper {
  padding: 10px;
}

.buttonWrapper {
  padding-bottom: 25px;
}

.shortThePonzi {
  color: white;
  background-color: #CC2828 !important;
  text-transform: none !important;
}

.denomWrapper {
  padding: 50px;
}

.bottomPadding {
  padding: 50px;
}

.boxContainer {
  padding-left: 25px;
  padding-right: 25px;
}



</style>
