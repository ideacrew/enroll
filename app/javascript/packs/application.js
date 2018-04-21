import Vue from 'vue/dist/vue.esm'
import VueResource from 'vue-resource'
Vue.use(VueResource);

import App from '../app.vue'
import Py from '../py.vue'
import Plan from '../plan.vue'
import PlanDetail from '../plan_detail.vue'
import OfficeLocation from '../office_location.vue'


// Vue.component('planitem', Plan);
// Vue.component('plan-year', Py);
// Vue.component('plan-detail', PlanDetail);
Vue.component('office-location', OfficeLocation);


window.Vue = Vue;


// document.addEventListener("turbolinks:load", function() {
//   console.log('turbolinks load');


  // var app = new Vue({
  //   el: '#app',
  //   data: {
  //     rows: [{id: 1, address: '812 Cattail Ct', city: 'West Melbourne'}]
  //   },
  //   created: function () {
  //     console.log('Loading data')
  //     // this.$http.get('/welcome/load_data').then(response => {
  //     //   console.log('Response: ' + response.body);
  //     //   this.rows = response.body;
  //     // }, response => {
  //     //   console.log('Error occurred trying to fetch key');
  //     // });
  //   },
  //   methods: {
  //       addRow(){
  //         this.$http.get('/welcome/random_key').then(response => {
  //           console.log('Response: ' + response.body);
  //           this.rows.push({id: response.body.key});
  //         }, response => {
  //           console.log('Error occurred trying to fetch key');
  //         });
  //
  //       },
  //       removeRow(index){
  //           this.rows.splice(index,1);
  //       }
  //   }
  // });


// });
