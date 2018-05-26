<template>
  <div>
    <h1 id="introduction" class="display-1 primary--text">Plans by Carriers</h1>

    <br>

    <v-tabs
      grow
      slider-color="blue"
      class="display-1"
    >

    <carrier v-for="(tab, index) in tabs"
                      :carrier="tab.carrier"
                      v-on:click="currentTab = tab"
                      v-on:myclick="clickedOn(tab, index)"
                      :key="index">
    </carrier>

    </v-tabs>

<v-layout row justify-center>
  <v-flex xs3>
    <v-card flat>
      <v-card-title primary-title>
        <img v-bind:src="currentTab.carrier.image" width="80px">
      </v-card-title>
      <v-card-text>
        <h3 class="headline mb-0">{{currentTab.carrier.name}}</h3>
        <p>Plan count: {{plan_count}}</p>
      </v-card-text>
    </v-card>
  </v-flex>
  <v-flex  xs9 order-lg2>
    <v-card flat >
      <v-card-text>
          <!--Plans from {{currentTab.carrier.name}}-->
          <!--<pre>{{plans}}</pre>-->
          <v-progress-linear slot="progress" color="blue" :indeterminate="isLoading"></v-progress-linear>
          <carrier-datatable :plans="plans"></carrier-datatable>
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
      currentTab: '',
      isLoading: false,
      tabs: [{carrier: { name: 'Kaiser', id: 123}},
              {carrier: { name: 'UHC', id: 456}},
              {carrier: { name: 'Cigna', id: 888}},
              {carrier: { name: 'BlueShield', id: 999}},
              {carrier: { name: 'BlueCross', id: 789}}],
      plans: []
    }
  },
  created: function () {
    this.load_carrier_names()
    this.currentTab = this.tabs[0];
    console.log('Loading data ...')
    // this.$http.get(this.$root.office_location_path).then(response => {
    //   console.log('Response: ' + response.body);
    //   this.rows = response.body;
    // }, response => {
    //   console.log('Error occurred trying to fetch office locations');
    // });
  },
  computed: {
    plan_count: function () {
      return this.plans.length;
    }
  },
  methods: {
      addRow(){
        this.tabs.push({carrier: {name: 'Tony', id: '1234'}});
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
      loadPlansFor(carrier_id){
        this.isLoading = true;
        this.plans = [];
        var self = this
        console.log('load plans for carrier id... ' + carrier_id)
        this.$http.get("/vue/" + carrier_id + "/load_plans")
        .then(response => {
          this.isLoading = false;
          this.plans = response.body
        }, response => {
          this.isLoading = false;
          console.error(response.body);
        });
      },
      save(){
        var self = this
        this.$http.post(this.$root.office_location_save_path, {office_locations: this.rows})
        .then(response => {
          console.log(response.body);
        }, response => {
          console.error(response.body);
        });
      },
      removeRow(index){
          this.tabs.splice(index,1);
      },
      clickedOn(tab, index) {
        console.log('clicked on: ' + tab + ', ' + index);
        this.currentTab = tab;
        this.loadPlansFor(tab.carrier.id)
      }
  }
}
</script>
