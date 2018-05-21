<template>
   <v-tab v-on:click="info" class="heading">
      <!--<v-btn color="info" v-on:click="info"></v-btn>-->
      {{cname}}
  </v-tab>
</template>

<script>
export default {
  data: function() {
    return {
      name: this.carrier.name,
      id: this.carrier.id
    }
  },
  props: ['carrier'],
  methods: {
    info() {
      console.log(JSON.stringify(this.name));
      this.$emit('myclick');
    }
  },
  computed: {
    cname: function () {
    return this.carrier.name;
  }
  }
}
</script>
