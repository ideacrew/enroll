<template>
  <div>
    <b-form >
      <b-form-group>
        <b-form-input id="exampleInput1"
                      type="email"

                      required
                      placeholder="Enter email">
        </b-form-input>
      </b-form-group>
      <b-form-group id="exampleInputGroup2"
                    label="Your Name:"
                    label-for="exampleInput2">
        <b-form-input id="exampleInput2"
                      type="text"

                      required
                      placeholder="Enter name">
        </b-form-input>
      </b-form-group>
      <b-form-group id="exampleGroup4">
        <b-form-checkbox-group  id="exampleChecks">
          <b-form-checkbox value="me">Check me out</b-form-checkbox>
          <b-form-checkbox value="that">Check that out</b-form-checkbox>
        </b-form-checkbox-group>
      </b-form-group>
      <b-button type="submit" variant="primary">Submit</b-button>
      <b-button type="reset" variant="danger">Reset</b-button>
    </b-form>
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
    // this.load_carrier_names()
    // this.currentTab = this.tabs[0];
    // console.log('Loading data ...')
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
