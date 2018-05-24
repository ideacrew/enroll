<template>
  <div>
    <h1 id="introduction" class="display-1 primary--text">Employee Form</h1>

    <br>
<v-container>
  <v-card>
  <v-form ref="form">
  <v-layout row wrap>
    <v-flex sm2 class="ma-3">
      <v-text-field
        label="First Name"
        required
      ></v-text-field>
    </v-flex>
    <v-flex sm2 class="ma-3">
      <v-text-field
        label="Middle"
      ></v-text-field>
    </v-flex>
    <v-flex sm2 class="ma-3">
      <v-text-field
        label="Last Name"
        required
      ></v-text-field>
    </v-flex>
  </v-layout>
  <v-layout row wrap>
    <v-flex sm2 class="ma-3">
      <v-text-field
        label="Date of Birth"
        required
      ></v-text-field>
    </v-flex>
    <v-flex sm2 class="ma-3">
      <v-text-field
        label="SSN"
        required
      ></v-text-field>
    </v-flex>
    <v-flex sm2 class="ma-3 align-content-start align-start">
        <v-radio-group label="Gender" :mandatory="true" row >
          <v-radio label="Male" value="radio-1" class="text-xs-right"></v-radio>
          <v-radio label="Female" value="radio-2" class="text-xs-right"></v-radio>
        </v-radio-group>
    </v-flex>
  </v-layout>
</v-form>
</v-card>
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
      costs: {}
    }
  }
}
</script>

<style>
.tony {
  border: 3px solid #000;
}
</style>
