<template>
  <div>

    <v-container  class="ma-2">
      <h1 class="display-1">Employee Detail</h1>
      <v-btn @click="$router.go(-1)" fab dark color="red"><v-icon>keyboard_arrow_left</v-icon></v-btn>
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
