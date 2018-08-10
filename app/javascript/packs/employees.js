import Vue from 'vue/dist/vue.esm';
import VueResource from 'vue-resource';

import BootstrapVue from 'bootstrap-vue';

Vue.use(VueResource);

Vue.use(BootstrapVue);

//import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'

//import 'vuetify/dist/vuetify.min.css' // Ensure you are using css-loader

import EmployeeMatch from '../employee_match.vue'


Vue.component('employee-match', EmployeeMatch);


const routes = [
  // { path: '/bqt', name: 'bqt', component: Bqt },
  // { path: '/hbx', name: 'hbx', component: Hbx },
  // { path: '/employer-home/:id', name: 'employer-home', component: EmployerHome,
  //   children: [
  //     {
  //       path: 'employer-my', component: EmployerSummary
  //     },
  //     {
  //       path: 'employer-employees', component: EmployerEmployees
  //     },
  //     {
  //       path: 'employer-employee-detail/:census_employee_id', component: EmployerEmployeeDetail
  //     },
  //     {
  //       path: 'employer-benefits', component: EmployerBenefits
  //     },
  //     {
  //       path: 'plan-year', component: EmployerPlanYear
  //     },
  //   ]
  // },
  // { path: '/plan-cost', name: 'planCost', component: PlanCost }
]


// var router = new VueRouter({
//   routes // short for `routes: routes`
// })

$(document).on('ready page:load', function () {
  console.log('on page employee_match app');

  const element = document.getElementById("employee_match");

  if (element!=null) {
    console.log('element is hbx')
    const props = JSON.parse(element.getAttribute('data'))
    console.log(props)
    var hbx = new Vue({
    el: '#employee_match',
    //store,
    //router: router,
    data: props,
    computed: {
    cmp: function () {
      return this.link
      }
    }
    });
  }
});
