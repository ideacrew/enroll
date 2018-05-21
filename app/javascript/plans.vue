<template>
<div class="plan col">
  This is a Plan {{message}}!<br>
  {{plan.carrier}}<br>
  <b>{{plan.metal}}</b>
</div>
</template>

<script>
console.log('load plan');
export default {
  data: function() {
    return {
      message: "My Plan"
    }
  },
  props: ['plan']
}
</script>

<style scoped>
.plan {
  border: 1px solid #777;
  font-size: 2em;
  text-align: center;
}
</style>
