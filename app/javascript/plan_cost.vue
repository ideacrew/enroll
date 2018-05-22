<template>
  <div>
    <h1 id="introduction" class="display-1 primary--text">Plans Cost Estimator</h1>

    <br>
<v-container fluid grid-list-lg>
<v-layout row wrap>
      <v-flex sm4>
        <v-card class="mb-2 blue lighten-5">
          <v-card-title primary-title>
            <h3 class="titile mb-0">{{selectedPlan.carrier_name}} {{selectedPlan.plan}}</h3>
          </v-card-title>
          <v-card-text>
            Contribution %<br>
            {{employee_contribution}} - Employee<br>
            {{spouse_contribution}} - Spouse<br>
            {{children_contribution}} - Children<br>
          </v-card-text>
        </v-card>
        <v-card  class="my-2">
          <v-card-text>
            Roster For Employer
            <v-select
               :items="employers"
               label="Select"
               v-model="selectedEmployer"
               item-text="legal_name"
               item-value="id"
               return-object
               single-line
               auto
               hide-details
             ></v-select>
          </v-card-text>
        </v-card>
        <v-card  class="my-2">
          <v-card-text>
            <span>Contribution %</span>
            <v-slider step="5" value="50" max="100" hint="${employee_contribution}" v-model="employee_contribution" label="Employee"></v-slider>
            <v-slider step="5" max="100" v-model="spouse_contribution" label="Spouse"></v-slider>
            <v-slider step="5" max="100" v-model="children_contribution" label="Children"></v-slider>
          </v-card-text>
        </v-card>
        <v-card>
          <v-card-text>
            <span class="text-md-center"><v-btn v-show="selectedEmployer.legal_name != 'none' && selectedPlan.plan != false" v-on:click="request_calc()" color="error" dark large>Show Estimated Cost</v-btn></span>
          </v-card-text>
        </v-card>
        <v-card  class="my-2">
          <v-card-text>
            <pre>
            {{all_data}}
            </pre>
          </v-card-text>
        </v-card>
      </v-flex>
      <v-flex sm8>
        <v-card>
          <v-container fluid justify-start style="max-height: 480px" class="scroll-y">
            <v-layout row wrap>
              <v-flex ma-1 v-for="(plan, index) in plan_filter"
                                v-on:click="selectedPlan = plan; clearAllPlans(plan)"
                                :key="index">
                <v-card hover width="340">
                  <v-card-title primary-title>
                    <img v-bind:src="plan.image_url" width="80px" class="pb-2">
                    <h3 class="title mb-0">{{plan.carrier_name}} : {{plan.plan}}</h3>
                  </v-card-title>
                  <v-card-text v-bind:class="plan.render_class">
                    <p>Metal Level: {{plan.metal_level}}</p>
                    <p>Nationwide: {{plan.nationwide}}</p>
                  </v-card-text>
                </v-card>
              </v-flex>
            </v-layout>
          </v-container>
        </v-card>

  </v-flex>
</v-layout>
</v-container>

<v-layout row justify-center>
  <v-dialog v-model="dialog" persistent max-width="600">
    <v-card>
      <v-card-title class="headline mb-3">Cost Estimator for&nbsp;<span class="blue--text">{{selectedEmployer.legal_name}}</span></v-card-title>
      <v-card-text>
        <div class="body-2 py-3">Employer Cost: ${{costs.employer_amount}}</div>
        <span class="body-2 py-3">Min/Max Employee Cost: ${{costs.min_employee_cost}} / {{costs.max_employee_cost}}</span><br>
      </v-card-text>
      <v-card-actions>
        <v-spacer></v-spacer>
        <v-btn color="blue darken-1" flat @click.native="dialog = false">Close</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</v-layout>


  </div>
</template>

<script>
export default {
  data: function() {
    return {
      dialog: false,
      package: {
        start_on: '2018-06-01',
        plan_option_kind: 'metal_level',
        coverage_type: '.health',
        benefit_group_index: '0',
        reference_plan_id: '5af0face8678292af10160f2',
        employer_profile_id: '5af1000a86782928ef000dd7',
        relation_benefits: {
          '0': {relationship: 'employee', premium_pct: 70, offered: true},
          '1': {relationship: 'spouse', premium_pct: 70, offered: true},
          '2': {relationship: 'domestic_partner', premium_pct: 70, offered: true},
          '3': {relationship: 'child_under_26', premium_pct: 70, offered: true},
          '4': {relationship: 'child_26_and_over', premium_pct: 70, offered: true}
        }
      },
      isLoading: false,
      plans: [],
      selectedPlan: {plan: false},
      selectedEmployer: {legal_name: 'none'},
      employers: [],
      employee_contribution: 50,
      spouse_contribution: 0,
      children_contribution: 0,
      selected_class: 'blue lighten-5',
      filter_metal_level: ['Silver','Gold','Platinum'],
      filter_nationwide: ['Yes','No'],
      costs: {}
    }
  },
  created: function () {
    this.loadPlans()
    this.loadEmployers()
    console.log('Loading data ...')
  },
  computed: {
    plan_count: function () {
      return this.plans.length;
    },
    all_data: function() {
      return this.$data
    },
    plan_filter: function () {
      return this.plans.filter(function (plan) {
        return ['Silver','Gold'].includes(plan.metal_level) && ['Yes','No'].includes(plan.nationwide)
      })
    }
  },
  methods: {
      request_calc() {
        console.log('... ' + this.selectedEmployer.id)
        this.package.employer_profile_id = this.selectedEmployer.id
        this.package.reference_plan_id = this.selectedPlan.id
        console.log('calculate for Employer ... ' + this.package.employer_profile_id)
        this.$http.post("/vue/calc", this.package)
        .then(response => {
          this.dialog = true
          this.costs = response.body
          console.error(response.body);
        }, response => {
          console.log('error')
          //console.error(response.body);
        });
      },
      load_carrier_names() {
        console.log('loading carriers...')
        this.$http.get("/vue/carriers")
        .then(response => {
          console.log(this.tabs);
          this.tabs = response.body
          console.log('---')
          console.log(this.tabs);
        }, response => {
          console.error(response.body);
        });
      },
      loadPlans() {
        this.plans = [];
        this.$http.get("/vue/plans")
        .then(response => {
          this.plans = response.body
        }, response => {
          console.error("error: " + response.body);
        });
      },
      loadEmployers() {
        this.employers = [];
        this.$http.get("/vue/employers")
        .then(response => {
          this.employers = response.body
        }, response => {
          console.error("error: " + response.body);
        });
      },
      clickedOn(tab, index) {
        console.log('clicked on: ' + tab + ', ' + index);
      },
      clearAllPlans(plan) {
        console.log('clearing...' + this.plans.length);
        for (var i = 0; i < this.plans.length; i++) {
          this.plans[i]['render_class'] = '';
        }
        plan['render_class'] = 'blue lighten-5';
      }
  }
}
</script>

<style>
.tony {
  border: 3px solid #000;
}
</style>
