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
        v-on:change="$emit('setModel', element.option, model.name, element.id)"
      ></v-radio>
    </v-radio-group>
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
