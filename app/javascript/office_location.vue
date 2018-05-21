<template>
  <div id="address_info" class="row focus_effect personal-info-row">
    <div class="col-md-12 no-pd col-sm-12 col-xs-12">
        <div class="row row-form-wrapper no-buffer">
            <div class="col-md-2 col-sm-2 col-xs-12 form-group form-group no-pd">
              <button class="btn btn-new-address" v-on:click="info">INFO</button><button class="btn btn-new-address" v-on:click="remove">REMOVE</button>
            </div>
          </div>

          <div class="row row-form-wrapper no-buffer">
            <div class="col-md-6 col-sm-6 col-xs-12 form-group form-group-lg no-pd">
              <input v-model="office.address_1" type="text" class="floatlabel form-control" required="true"  placeholder="ADDRESS LINE 1">
            </div>
            <div class="col-md-6 col-sm-6 col-xs-12 form-group form-group-lg no-pd">
              <input v-model="office.address_2" type="text" class="floatlabel form-control" placeholder="ADDRESS LINE 2">
            </div>
          </div>

          <div class="row row-form-wrapper no-buffer">
              <div class="col-md-4 col-sm-4 col-xs-12 form-group form-group-lg no-pd">
                <input v-model="office.city" type="text" class="floatlabel form-control interaction-field-control-office-location-address-city" required="true" placeholder="CITY">
              </div>
              <div class="col-md-4 col-sm-4 col-xs-12 form-group form-group-lg no-pd">
                <input v-model="office.state" type="text" class="floatlabel form-control st interaction-field-control-office-location-address-state" required="true" placeholder="STATE">
              </div>
              <div class="col-md-4 col-sm-4 col-xs-12 form-group form-group-lg no-pd">
                <input v-model="office.zip" type="text" class="floatlabel form-control zip interaction-field-control-office-location-address-zip" required="true" placeholder="ZIP">
              </div>
          </div>
      </div>
      </br></br>
  </div>
</template>

<script>
export default {
  data: function() {
    return {
      office_kinds: ['Primary','Mailing','Other'],
      address_1: this.info.address_1,
      address_2: this.info.address_2,
      city: this.office.city,
      state: this.office.state,
      zip: this.office.zip
    }
  },
  props: ['office'],
  methods: {
    remove() {
      if(confirm('Are you sure you want to delete this office location?'))
        this.$emit('delete');
    },
    info() {
      alert(JSON.stringify(this.office))
    }
  }
}
</script>

<style scoped>
</style>
