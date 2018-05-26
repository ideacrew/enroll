<template>
  <div class="ma-2">
      <h1 class="display-1">Benefits</h1>

      <v-card class="mt-3 pa-3">
          <span class="display-1 blue--text">{{ plan_years.benefit_groups[0].title }}</span>

          <v-container fluid class="mt-3">
            <v-layout row class="grey--text">
            <v-flex><span class="title">Coverage Year</span></v-flex>
            <v-flex class="body-2">{{ plan_years.start_on }} to {{ plan_years.end_on }}</v-flex>
            </v-layout>
            <v-layout row class="mt-3">
              <v-flex>
                <v-layout d-block>
                <v-flex>REFERENCE PLAN</v-flex>
                <v-flex>My Cool Plan</v-flex>
              </v-layout>
              </v-flex>
              <v-flex>
                CARRIER
              </v-flex>
              <v-flex>
                TYPE
              </v-flex>
              <v-flex>
                METAL LEVEL
              </v-flex>
            </v-layout>
          </v-container>

          <pre>
            {{ plan_years }}
          </pre>
      </v-card>

  </div>
</template>

<script>
export default {
  data: function() {
    return {
      dialog: false,
      plan_years: []
    }
  },
  created: function ()  {
    this.loadPlanYear()
  },
  methods: {
    loadPlanYear() {
      console.log('loading plan_year...')
      this.$http.get("/vue/plan_year?employer_id=" + this.$route.params.id)
      .then(response => {
        this.plan_years = response.body
      }, response => {
        console.log("Error loading employees");
      });
    },
  }
}
</script>

<style>
</style>
