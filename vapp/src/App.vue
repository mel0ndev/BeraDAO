<template>
  <v-app v-if="isDrizzleInitalized" id="inspire">
    <v-navigation-drawer
      v-model="drawer"
      app
      color="#2a2a2a"
      dark
    >
    <div>
      <v-list rounded dark>
      <v-list-item-content class="itemContent">
        <v-list-item-title class="title"
        align="center"
        justify="center">
            Dashboard
        </v-list-item-title>

        <v-divider dark></v-divider>

          <v-list-item class="itemlist" v-for="routerLink in routerLinks"
          :key="routerLink.name"
          :to="routerLink.link"
          >
          <v-icon class="itemIcon" color="white" dense>
            {{routerLink.icon}}
          </v-icon>
            {{routerLink.name}}

          </v-list-item>
      </v-list-item-content>
    </v-list>
    </div>
      <!--  -->
    </v-navigation-drawer>

    <v-app-bar
    app
    color="#191919"
    dark
    rounded
    >
      <v-app-bar-nav-icon @click="drawer = !drawer"></v-app-bar-nav-icon>


              <v-toolbar-title class="logoWrapper">
                <v-img src="./assets/beraDAO.png"
                height="100"
                width="150"
                >

                </v-img>
              </v-toolbar-title>

              <div class="account">
                <Account />
            </div>

          </v-app-bar>

    <v-main>

      <div id="app">
        <router-view/>
      </div>

    </v-main>
  </v-app>

  <div v-else> Loading... </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Account from "./components/Account.vue";

  export default {

    components: {
      Account
    },

    computed:
         mapGetters('drizzle', ['isDrizzleInitialized']),
    data() {
      return {
        drawer: false,
        isDrizzleInitalized: true,
        routerLinks: [
          {name: "Home", link: "/", icon: "mdi-home"},
          {name: "Swap and Short", link: "/Short", icon: "mdi-information"}
        ],
      }
    }
  }
</script>


<style>

#inspire{
  background-color: #0c0c0c;
  background-image: url("./assets/bg.png");
  background-position: center;
  background-size: cover;
}

.itemContent {
  padding-bottom: 20px;
}

.itemIcon {
  padding-right: 10px;
}

.logoWrapper {
  padding-top: 20px;
  padding-bottom: 5px;
}

.title {
  align-items: center;
  justify-content: center;
  padding-bottom: 10px;
}

.account {
  position: absolute;
  right: 2%;
  color: #939393;
}


</style>
