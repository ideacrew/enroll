<template>
  <div>
    <v-container class="ma-2">
    <v-data-table
      :headers="headers"
      :items="census_employees"
      item-key="name"
      class="elevation-1"
    >
      <template slot="items" slot-scope="props">
        <tr @click="props.expanded = !props.expanded">
          <td>{{ props.item.first_name }} {{ props.item.last_name }}</td>
          <td><router-link :to="{ path: `/employer-home/${$route.params.id}/employer-employee-detail`}">Details</router-link></td>
        </tr>
      </template>
      <template slot="expand" slot-scope="props">
        <v-card flat class="blue lighten-5">
          <v-card-text>{{ props.item.first_name }}</v-card-text>
        </v-card>
      </template>
    </v-data-table>
    </v-container>
</div>
</template>

<script>
export default {
  data: function() {
    return {
      census_employees: [],
      headers: [
        { text: 'Name', value: 'name', align: 'left', width: 250 },
        { text: 'Details'}
      ]
    }
  },
  props: ['employees'],
  activated: function () {
    console.log('Loading data ...')
    console.log('route id: ' + this.$route.params.id)
    this.loadCensusEmployees()
    // this.$http.get(this.$root.office_location_path).then(response => {
    //   console.log('Response: ' + response.body);
    //   this.rows = response.body;
    // }, response => {
    //   console.log('Error occurred trying to fetch office locations');
    // });
  },
  computed: {
  },
  methods: {
    loadCensusEmployees() {
      console.log('loading employees...')
      this.$http.get("/vue/my_employees")
      .then(response => {
        this.census_employees = response.body
      }, response => {
        console.error("Error loading employees");
      });
    },
  }
}
</script>
