<template>
  <div>

  <h1 class="display-1">Broker Quoting Tool</h1>

  <p>&nbsp;</p>

  <v-layout row wrap>
    <v-flex sm6>
      <v-card class="mb-2 mr-2" disable>
        <v-card-title primary-title>
          <h3 class="titile mb-0">Benefit Model Selection</h3>
        </v-card-title>
        <v-card-text>
          <!-- <bqt-model v-for="(model, index) in models"
                            v-on:click.native="saySelected(model)"
                            :model="model"
                            :key="index"></bqt-model> -->
            <v-btn class="blue darken-4 white--text" v-on:click="selectedModel = models[0]">{{models[0].name}}</v-btn>
            <v-btn class="blue darken-4 white--text disabled" v-on:click="selectedModel = models[1]">{{models[1].name}}</v-btn>
            <v-btn class="blue darken-4 white--text" v-on:click="selectedModel = models[2]">{{models[2].name}}</v-btn>
            <bqt-model v-bind:model="selectedModel" @hello="onClickChild"></bqt-model>
        </v-card-text>
      </v-card>
    </v-flex>
    <v-flex sm6>
      <v-card class="mb-2 ml-2">
        <v-card-title primary-title>
          <h3 v-show="!selectedCriteria" class="titile mb-0">No current selection.</h3>
          <h3 v-show="selectedCriteria" class="titile mb-0">Plans for your model by {{selectedCriteria.model}}</h3>

        </v-card-title>
        <v-card-text>
          <p v-show="selectedCriteria">
            <v-btn @click="loadPlans()">Show {{selectedCriteria.criteria}} plans</v-btn>
          </p>

          <p>
            {{plans}}
          </p>
        </v-card-text>
      </v-card>
    </v-flex>
  </v-layout>



  </div>
</template>

<script>

export default {
  data: function() {
    return {
      models: [ { name : "Single Plan",
                  criteria: [{id: 1234, option : "BCM"}, {id: 345, option : "BlueCross"}, {id: 883, option : "Aetna"}],
                  text: "Select your preferred insurance company carrier. You will then select one plan and it'll be the only plan your participants can choose."},
                { name : "One Level",
                  criteria: [{id: 1, option : "Silver"}, {id: 2, option : "Gold"}],
                  text: "Select your preferred insurance company carrier. Your plan participants will be able to choose any Platinum, Gold, or Silver plan offered by the carrier you select. Your costs will be fixed to a specific plan you’ll choose in a minute."},
                { name : "Single Carrier",
                  criteria: [{id: 1234, option : "BCM"}, {id: 345, option : "BlueCross"}, {id: 883, option : "Aetna"}],
                  text: "Select your preferred metal level. Your plan participants will be able to choose any plan by any carrier within the metal level you select. Your costs will be fixed to a specific plan you’ll choose in a minute. Silver means the plan is expected to pay 70% of expenses for an average population of consumers, and Gold 80%."}],
      selectedModel: false,
      selectedCriteria: false,
      plans: []
    }
  },
  methods: {
      onClickChild(criteria, model, c) {
        console.log(model +  ' ' + criteria);
        this.selectedCriteria = {model: model, criteria: criteria}
      },
      saySelected(m){
        this.selectedModel = m;
        alert(m.name);
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
  },
  created: function () {
    //this.selectedModel = this.models[0];
    //console.log('BQT ... ' + this.selectedModel.name)
    // this.$http.get(this.$root.office_location_path).then(response => {
    //   console.log('Response: ' + response.body);
    //   this.rows = response.body;
    // }, response => {
    //   console.log('Error occurred trying to fetch office locations');
    // });
  },
}
</script>

<style>
</style>
