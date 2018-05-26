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
import EmployeeDetails from '../employee_details.vue'
import EmployerHome from '../employer_home.vue'
import EmployerSummary from '../employer/my.vue'
import EmployerEmployees from '../employer/employees.vue'
import EmployerEmployeesDatatable from '../employer/employee_datatable.vue'


Vue.component('hbx', Hbx);
Vue.component('carrier', Carrier);
Vue.component('carrier-datatable', CarrierDatatable);
Vue.component('plan-cost', PlanCost);
Vue.component('employee-details', EmployeeDetails);
Vue.component('employer-home', EmployerHome);
Vue.component('employer-my', EmployerSummary);
Vue.component('employer-employees', EmployerEmployees);
Vue.component('employer-employees-datatable', EmployerEmployeesDatatable);

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
