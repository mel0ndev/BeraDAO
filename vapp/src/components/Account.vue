<template>
  <span>
    Welcome, <strong>{{activeAccount}} </strong>
  </span>

</template>


<script>
import { mapGetters } from "vuex";

export default {
name: 'Account',
computed:
  mapGetters('accounts', ['activeAccount']),
}
</script>
