<template>
  <v-card flat
    dark
    class="main"
    >
    <h1 class="heading">
        Withdraw
    </h1>

    <v-row>
      <v-col
      justify="center"
      align="center"
      >
        <h3 class="subheading"> Standard Risk Pool Liquidity </h3>
        <h4> ass </h4>
      </v-col>

      <v-col
      justify="center"
      align="center"
      >
        <h3 class="subheading"> High Risk Pool Liquidity </h3>
        <h4> ass too </h4>
      </v-col>
    </v-row>

  </v-card>
</template>

<script>

export default {
name: 'WithdrawDialog'

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
    color: white;
    padding-bottom: 10px;
    padding-top: 20px;
}




</style>
