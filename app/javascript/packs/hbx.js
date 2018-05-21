import Vue from 'vue/dist/vue.esm'
import VueResource from 'vue-resource'
//import BootstrapVue from 'bootstrap-vue';
import Vuetify from 'vuetify';

Vue.use(VueResource);
Vue.use(Vuetify);

// import 'bootstrap/dist/css/bootstrap.css'
// import 'bootstrap-vue/dist/bootstrap-vue.css'
// Helpers

import 'vuetify/dist/vuetify.min.css' // Ensure you are using css-loader

import Hbx from '../hbx.vue'
import Carrier from '../carrier.vue'
import CarrierDatatable from '../carrier_datatable.vue'
import PlanCost from '../plan_cost.vue'


Vue.component('hbx', Hbx);
Vue.component('carrier', Carrier);
Vue.component('carrier-datatable', CarrierDatatable);
Vue.component('plan-cost', PlanCost);

$(document).on('ready page:load', function () {
  console.log('on page hbx app');

  const element = document.getElementById("hbx");

  if (element!=null) {
    console.log('element is hbx')
    const props = JSON.parse(element.getAttribute('data'))
    console.log(props)
    var hbx = new Vue({
    el: '#hbx',
    data: props,
    computed: {
    cmp: function () {
      return this.link
      }
    }
    });
  }
});
