<template>
  <div>
    <p>&nbsp;</p>
    <h3>
      By {{model.name}}
    </h3>
    <p>
      {{model.text}}
    </p>

    <v-radio-group row :name="model.name" :value="model.name">
      <v-radio v-for="(element, index) in model.criteria"
        :label="element.option"
        color="red"
        :value="element.id"
        v-on:change="$emit('hello', element.option, model.name)"
      ></v-radio>
    </v-radio-group>

<!-- v-on:click="$emit('hello', element.option, model.name)" -->
    <!--<p><button v-on:click="$emit('hello', 1, model.name)">say</button></p>-->
  </div>
</template>

<script>
export default {
  props: ['model'],
  data: function() {
    return {
      dialog: false
    }
  }
}
</script>

<style>
</style>
