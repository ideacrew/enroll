<template>
  <div>


  <h1 class="display-1">Broker Quoting Tool</h1>

  <p>&nbsp;</p>

  <v-layout row wrap>
    <v-flex sm6>
      <v-card class="mb-2 mr-2" v-bind:class="[isShowing ? blurClass : '', bkClass]">
        <v-card-title primary-title>
          <h3 class="titile mb-0">Benefit Model Selection</h3>
        </v-card-title>
        <v-card-text>
            <v-btn class="blue darken-4 white--text" v-on:click="selectedModel = models[0]">{{models[0].name}}</v-btn>
            <v-btn class="blue darken-4 white--text" v-on:click="selectedModel = models[1]">{{models[1].name}}</v-btn>
            <v-btn class="blue darken-4 white--text" v-on:click="selectedModel = models[2]">{{models[2].name}}</v-btn>
            <bqt-model v-bind:model="selectedModel" @setModel="onClickChild"></bqt-model>
            <!--</div>-->
        </v-card-text>
      </v-card>
    </v-flex>
    <v-flex sm6>
      <v-card class="mb-2 ml-2">
        <v-card-title primary-title>
          <h3 v-show="!selectedCriteria" class="titile mb-0">No current selection.</h3>
          <h3 v-show="selectedCriteria" class="titile mb-0">Plans for your model by <u>{{selectedCriteria.model}}</u></h3>

        </v-card-title>
        <v-card-text>

          <p v-show="selectedCriteria">
            <v-btn @click="loadPlans()">Show {{selectedCriteria.criteria}} plans</v-btn>
          </p>

          <p v-show="latestStatusMessage">
            {{latestStatusMessage}}
          </p>

          <v-progress-circular
            v-show="loading"
            indeterminate
            color="primary"
            ></v-progress-circular>

          <p>
            <template v-for="(plan, index) in plans">
              <bqt-plan :plan="plan" :key="index"></bqt-plan>
            </template>
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
                  criteria: [{id: "53e67210eb899a460300001a", option : "BestLife"}, {id: "53e67210eb899a4603000004", option : "CareFirst"}, {id: "53e67210eb899a4603000007", option : "Aetna"}, {id: "53e67210eb899a460300000d", option: "Kaiser"}],
                  text: "Select your preferred insurance company carrier. You will then select one plan and it'll be the only plan your participants can choose."},
                { name : "One Level",
                  criteria: [{id: 1, option : "Silver"}, {id: 2, option : "Gold"}],
                  text: "Select your preferred insurance company carrier. Your plan participants will be able to choose any Platinum, Gold, or Silver plan offered by the carrier you select. Your costs will be fixed to a specific plan you’ll choose in a minute."},
                { name : "Single Carrier",
                  criteria: [{id: "53e67210eb899a460300001a", option : "BestLife"}, {id: "53e67210eb899a4603000004", option : "CareFirst"}, {id: "53e67210eb899a4603000007", option : "Aetna"}, {id: "53e67210eb899a460300000d", option: "Kaiser"}],
                  text: "Select your preferred metal level. Your plan participants will be able to choose any plan by any carrier within the metal level you select. Your costs will be fixed to a specific plan you’ll choose in a minute. Silver means the plan is expected to pay 70% of expenses for an average population of consumers, and Gold 80%."}],
      selectedModel: false,
      selectedCriteria: false,
      plans: false,
      latestStatusMessage: false,
      isShowing: false,
      bkClass: 'bk',
      blurClass: 'blur',
      loading: false
    }
  },
  methods: {
      onClickChild(criteria, model, c) {
        console.log(model +  ' ' + criteria + ' ' + c);
        this.selectedCriteria = {model: model, criteria: criteria, id: c};
        //this.toggleShow();
      },
      saySelected(m){
        this.selectedModel = m;
        alert(m.name);
      },
      toggleShow() {
        console.log('toggle')
        this.isShowing = !this.isShowing;
      },
      loadPlans() {

        this.plans = [];
        this.latestStatusMessage = false;

        this.loading = true;

        console.log("/vue/plans?model=" + this.selectedCriteria.model + "&criteria=" + this.selectedCriteria.criteria + "&id=" + this.selectedCriteria.id)
        this.$http.get("/vue/plans?model=" + this.selectedCriteria.model + "&criteria=" + this.selectedCriteria.criteria + "&id=" + this.selectedCriteria.id)
        .then(response => {
          this.loading = false;
          this.plans = response.body
          this.latestStatusMessage = "Showing " + this.plans.length + " plans for " + this.selectedCriteria.criteria
        }, response => {
          console.error("error: " + response.body);
        });
      },
  },
  created: function () {
    //this.selectedModel = this.models[0];
  },
}
</script>

<style>
.bk {
  transition: all 0.1s ease-out;
}

.blur {
  filter: blur(1px);
  background-color: #000;
  opacity: 0.7;
}


</style>
