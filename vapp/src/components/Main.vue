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
                @click.prevent="onSubmit"
                >
                Deposit
              </v-btn>
            </div>
            <span class="subheading">
                Available to deposit:
            </span>
            <span class="subheading">
              APY:
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
                @click.prevent="onSubmit"
                >
                Withdaw
              </v-btn>
            </div>
            <span class="subheading">
                Available for withdrawl:
            </span>
            <span class="subheading">
              PnL:
            </span>
          </v-card>
        </v-col>
      </v-row>



    </v-card>
  </v-col>
</v-row>





  </v-container>

</template>


<script>

export default {
  name: 'Main'

}


</script>


<style scoped>

.subheading {
  display: flex;
  justify-content: center;
  color: #939393;
  padding-bottom: 10px; 
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
