<template>
  <div class="plan">
    <p>
      <img :src="plan.image_url" width="60"><br>
      {{plan.plan}}
    </p>
  </div>
</template>

<script>
export default {
  props: ['plan'],
  data: function() {
    return {
      dialog: false
    }
  }
}
</script>

<style>
  .plan {
    margin: 2px 2px 2px 2px;
    padding: 3px 3px 3px 3px;
  }
</style>
