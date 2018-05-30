<template>
  <div class="ma-2">
      <h1 class="display-1">Plan year</h1>

      <v-card class="mt-3 pa-2 subheading">
      <v-container grid-list-lg>
        <v-layout>
          <v-flex>
          <div class="title grey--text text--darker-1">When would you like your coverage to start?</div>
          </v-flex>
        </v-layout>
        <v-layout>
          <v-flex>
            <v-select
              :items="coverage_dates"
              v-model="selected_coverage_date"
              label="Coverage Start"
              item-text="start_on_display"
              item-value="start_on_val"
              return-object
            ></v-select>
          </v-flex>
          <v-flex>
            <v-text-field label="Coverage End" v-model="selected_coverage_date.end_on_display"></v-text-field>
          </v-flex>
        </v-layout>
        <v-layout row>
          <v-flex>
          <div class="title">Select your open enrollment dates</div>
          </v-flex>
        </v-layout>
        <v-layout row>
          <v-flex>
            <v-menu
                ref="oe_start_menu"
                :close-on-content-click="false"
                v-model="oe_start_menu"
                :nudge-right="40"
                lazy
                transition="scale-transition"
                offset-y
                full-width
                min-width="290px"
              >
                <v-text-field slot="activator" v-model="oe_start_on" label="Open Enrollment Start Date" prepend-icon="event" readonly></v-text-field>
                <v-date-picker v-model="oe_start_on" no-title scrollable @input="oe_start_menu = false"></v-date-picker>
              </v-menu>
          </v-flex>
          <v-flex>
            <v-menu
                ref="oe_end_menu"
                :close-on-content-click="false"
                v-model="oe_end_menu"
                :nudge-right="40"
                lazy
                transition="scale-transition"
                offset-y
                full-width
                min-width="290px"
              >
                <v-text-field slot="activator" v-model="oe_end_on" label="Open Enrollment End Date" prepend-icon="event" readonly></v-text-field>
                <v-date-picker v-model="oe_end_on" no-title scrollable @input="oe_end_menu = false"></v-date-picker>
              </v-menu>
          </v-flex>
        </v-layout>
        <v-layout row>
          <v-flex>
          <div class="title">Add the total number of employees in your workforce</div>
          </v-flex>
        </v-layout>
        <v-layout row>
          <v-flex>
            <v-text-field label="FULL TIME EMPLOYEES" v-model="fte_count"></v-text-field>
          </v-flex>
          <v-flex>
            <v-text-field label="PART TIME EMPLOYEES" v-model="part_time_count"></v-text-field>
          </v-flex>
          <v-flex>
            <v-text-field label="SECONDARY MEDICARE" v-model="med_count"></v-text-field>
          </v-flex>
        </v-layout>
      </v-container>
      </v-card>

  </div>
</template>

<script>
export default {
  data: function() {
    return {
      dialog: false,
      fte_count: 0,
      part_time_count: 0,
      med_count: 0,
      plan_years: [],
      oe_start_on: null,
      oe_end_on: null,
      oe_start_menu : false,
      oe_end_menu : false,
      coverage_dates :[
        {start_on_display: "Jun 1, 2018", start_on_val : "06/01/2018", end_on_display: "May 31, 2019", end_on_val: "05/31/2019"},
        {start_on_display: "July 1, 2018", start_on_val : "07/01/2018", end_on_display: "Jun 30, 2019", end_on_val: "06/30/2019"}
      ],
      selected_coverage_date: {start_on_display: "Jun 1, 2018", start_on_val : "06/01/2018", end_on_display: "May 31, 2019", end_on_val: "05/31/2019"},
    }
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
    createPlanYear() {
      this.$router.push({path:`/employer-home/${this.$route.params.id}/plan-year`})
    }
  }
}
</script>

<style>
</style>
