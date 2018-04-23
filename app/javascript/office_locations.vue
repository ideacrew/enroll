<template>
  <div>
    <h3>Office Locations</h3>
    <office-location v-for="(row, index) in rows"
                      :office="row.address"
                      :key="index"
                      v-on:delete="removeRow(index)">
    </office-location>
    <div>
      <button @click="addRow"> Add Address </button>
      <button @click="save"> Save Data </button>
    </div>
    </br>
    <pre>{{rows}}</pre>
</div>
</template>

<script>
console.log('office locations ...');
export default {
  data: function() {
    return {
      rows: [{address: { address_1: '812 Cattail Ct', address_2: '', city: 'West Melbourne', st: 'FL', zip: '32904'}},
             {address: {address_1: '799 Fiddleleaf Cir', address_2: '', city: 'West Melbourne', st: 'FL', zip: '32904'}}],
    }
  },
  created: function () {
    console.log('Loading data ...')
    this.$http.get(this.$root.office_location_path).then(response => {
      console.log('Response: ' + response.body);
      this.rows = response.body;
    }, response => {
      console.log('Error occurred trying to fetch office locations');
    });
  },
  methods: {
      addRow(){
        this.rows.push({id: '', address: {}});
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
          this.rows.splice(index,1);
      }
  }
}
</script>
