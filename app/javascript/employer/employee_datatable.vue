<template>
  <v-container class="ma-2">
  <v-data-table
    :headers="headers"
    :items="employees"
    item-key="name"
    class="elevation-1"
  >
    <template slot="items" slot-scope="props">
      <tr @click="props.expanded = !props.expanded"><td>{{ props.item.name }}</td></tr>
    </template>
    <template slot="expand" slot-scope="props">
      <v-card flat class="blue lighten-5">
        <v-card-text>{{ props.item.nickname }}</v-card-text>
      </v-card>
    </template>
  </v-data-table>
  </v-container>
</template>

<script>
export default {
  data: function() {
    return {
      headers: [
        { text: 'Name', value: 'name', align: 'left', width: 250 }
      ]
    }
  },
  props: ['employees'],
  computed: {
  }
}
</script>
