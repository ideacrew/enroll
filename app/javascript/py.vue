<template>
<div>
  <h1>Plan Year</h1>
  <div class="row">
    <planitem v-for="(item, index) in plans" :key="index" :plan="item">{{item}}</planitem>
  </div>
</div>

</template>

<script>
export default {
  data: function() {
    return {
      message: "This is the Plan Year Vue",
      rows: [],
      plans: [
        {carrier: "Kaiser", metal: "gold", plan: "Plan 1"},
        {carrier: "Kaiser", metal: "silver", plan: "Plan 2"},
        {carrier: "Kaiser", metal: "platinum", plan: "Plan 3"},
        {carrier: "UHC", metal: "gold", plan: "Plan 4"},
        {carrier: "UHC", metal: "silver", plan: "Plan 5"},
      ]
    }
  }
}
</script>

<style scoped>
p {
  font-size: 2em;
  text-align: center;
}
</style>
