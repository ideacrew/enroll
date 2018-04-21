<template>
<div class="plan col">
This is plan detail
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
  border-bottom: 1px solid #ccc;
  font-size: 2em;
  text-align: center;
}
</style>
