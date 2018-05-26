<template>
  <div class="ma-2">

      <h1 class="display-1">Your Employee Roster</h1>

      <employer-employees-datatable :employees="employees"></employer-employees-datatable>

  </div>
</template>

<script>
export default {
  data: function() {
    return {
      dialog: false,
      employees: [{name: 'Tony', nickname: 'Brazilian'}, {name: 'Andrej', nickname: 'Serbian'}, {name: 'Chaz', nickname: 'UI Guru'}, {name: 'David', nickname: 'Isonator'}]
    }
  }
}
</script>

<style>
</style>
