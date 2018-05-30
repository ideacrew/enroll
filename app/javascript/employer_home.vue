<template>
  <div>

<v-container fluid grid-list-lg>
  <v-layout row>
    <v-flex>
    <v-select
       :items="employers"
       label=". . . "
       v-model="selectedEmployer"
       item-text="legal_name"
       item-value="id"
       return-object
       single-line
       auto
       @change="changeEmployer()"
     ></v-select>
   </v-flex>
  </v-layout>

  <v-layout row>
    <v-flex sm2 class="ma-2 pa-2">
      <v-card >
        <v-list two-line subheader>
          <v-list-tile :to="{path:`/employer-home/${$route.params.id}/employer-my`}">
            <v-list-tile-content >
              <v-list-tile-title>My DC Healthlink</v-list-tile-title>
              <v-list-tile-sub-title>Summary</v-list-tile-sub-title>
            </v-list-tile-content>
          </v-list-tile>
          <!-- <v-list-tile  v-on:click="link = 'employer-employees'"> -->
          <v-list-tile :to="{path:`/employer-home/${$route.params.id}/employer-employees`}">

            <v-list-tile-content>
              <v-list-tile-title>Employees</v-list-tile-title>
              <v-list-tile-sub-title>Employee Roster...</v-list-tile-sub-title>
            </v-list-tile-content>
          </v-list-tile>
          <v-list-tile :to="{path:`/employer-home/${$route.params.id}/employer-benefits`}">
            <v-list-tile-content>
              <v-list-tile-title>Benefits</v-list-tile-title>
              <v-list-tile-sub-title>Benefit Offerings...</v-list-tile-sub-title>
            </v-list-tile-content>
          </v-list-tile>
          <v-list-tile>
            <v-list-tile-content>
              <v-list-tile-title>Brokers</v-list-tile-title>
              <v-list-tile-sub-title>Your brokers</v-list-tile-sub-title>
            </v-list-tile-content>
          </v-list-tile>
          <v-list-tile>
            <v-list-tile-content>
              <v-badge color="red">
              <span slot="badge">2</span>
              <v-list-tile-title>
                  Documents
              </v-list-tile-title>
              </v-badge>
              <v-list-tile-sub-title>Documents ...</v-list-tile-sub-title>
            </v-list-tile-content>
          </v-list-tile>
      </v-list>
      </v-card>
    </v-flex>
    <v-flex sm10 class="ma-2 pa-2">
      <router-view/>
    </v-flex>
  </v-layout>
</v-container>

  </div>
</template>

<script>
export default {
  data: function() {
    return {
      dialog: false,
      selectedEmployer: {legal_name: 'none'},
      employers: [],
      link: 'employer-my'
    }
  },
  created: function ()  {
    this.loadEmployers()
  },
  methods: {
    loadEmployers() {
      this.employers = [];
      this.$http.get("/vue/employers")
      .then(response => {
        this.employers = response.body
        this.selectedEmployer = this.employers[0]
      }, response => {
        console.error("error: " + response.body);
      });
    },
    changeEmployer() {
      console.log(this.selectedEmployer)
      console.log('Clicked on: ' + this.selectedEmployer.id + ', ' + this.selectedEmployer.legal_name)
      this.$router.push({path:`/employer-home/${this.selectedEmployer.id}/employer-my`})
    }
  },
  computed: {
  cmp: function () {
    return this.link
    }
  }
}
</script>

<style>
</style>
