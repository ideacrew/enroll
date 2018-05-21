<template>
  <v-data-table
    :headers="headers"
    :items="plans"
    :loading="true"
    class="elevation-1"
  >
    <template slot="items" slot-scope="props">
      <td>{{ props.item.market }}</td>
      <td>{{ props.item.plan }}</td>
      <td>{{ props.item.metal_level }}</td>
      <td class="text-xs-right">{{ props.item.active_year }}</td>
    </template>
  </v-data-table>
</template>

<script>
export default {
  data: function() {
    return {
      headers: [
        { text: 'Market', value: 'market', align: 'left', width: 250 },
        {
          text: 'Plan Name',
          align: 'left',
          sortable: true,
          value: 'plan',
          width: 400
        },
        { text: 'Metal Level', value: 'metal_level', align: 'left', width: 250 },
        { text: 'Year', value: 'active_year', align: 'right' },
      ]
    }
  },
  props: ['plans'],
  computed: {
  }
}
</script>
