<template>
  <div class="ma-2">

  <h1 class="display-1">My Health Benefits Program</h1>
  <p class="body-1 ma-2">It's time to set up your Health Benefits Program. You can either get help from a Broker, or set up your Health Benefits Program yourself. Choose the path that's right for you.</p>

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
