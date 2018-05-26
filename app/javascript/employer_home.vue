<template>
  <div>

<v-container>
  <v-layout row>
    <v-flex sm2 class="ma-2 pa-2">
      <v-card >
        <v-list two-line subheader class="blue lighten-5">
          <v-list-tile v-on:click="link = 'employer-my'">
            <v-list-tile-content >
              <v-list-tile-title>My DC Healthlink</v-list-tile-title>
              <v-list-tile-sub-title>Summary</v-list-tile-sub-title>
            </v-list-tile-content>
          </v-list-tile>
          <v-list-tile  v-on:click="link = 'employer-employees'">
            <v-list-tile-content>
              <v-list-tile-title>Employees</v-list-tile-title>
              <v-list-tile-sub-title>Employee Roster...</v-list-tile-sub-title>
            </v-list-tile-content>
          </v-list-tile>
          <v-list-tile>
            <v-list-tile-content>
              <v-list-tile-title>Benefits</v-list-tile-title>
              <v-list-tile-sub-title>Benefit Offerings...</v-list-tile-sub-title>
            </v-list-tile-content>
          </v-list-tile>
          <v-list-tile>
            <v-list-tile-content>
              <v-list-tile-title>Brokers</v-list-tile-title>
              <v-list-tile-sub-title>Your brokers</v-list-tile-sub-title>
            </v-list-tile-content>
          </v-list-tile>
      </v-list>
      </v-card>
    </v-flex>
    <v-flex sm10 class="ma-2 pa-2">
      <component v-bind:is="cmp"></component>
    </v-flex>
  </v-layout>
</v-container>

  </div>
</template>

<script>
export default {
  data: function() {
    return {
      dialog: false,
      isLoading: false,
      plans: [],
      selectedPlan: {plan: false},
      selectedEmployer: {legal_name: 'none'},
      employers: [],
      employee_contribution: 50,
      spouse_contribution: 0,
      children_contribution: 0,
      selected_class: 'blue lighten-5',
      filter_metal_level: ['Silver','Gold','Platinum'],
      filter_nationwide: ['Yes','No'],
      costs: {},
      link: 'employer-my'
    }
  },
  computed: {
  cmp: function () {
    return this.link
    }
  }
}
</script>

<style>
</style>
