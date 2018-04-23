import Vue from 'vue/dist/vue.esm'
import VueResource from 'vue-resource'
import TurbolinksAdapter from 'vue-turbolinks';
Vue.use(VueResource);
Vue.use(TurbolinksAdapter)

import App from '../app.vue'
import Py from '../py.vue'
import Plan from '../plan.vue'
import PlanDetail from '../plan_detail.vue'
import OfficeLocation from '../office_location.vue'
import OfficeLocations from '../office_locations.vue'


// Vue.component('planitem', Plan);
// Vue.component('plan-year', Py);
// Vue.component('plan-detail', PlanDetail);

Vue.component('office-locations', OfficeLocations);
Vue.component('office-location', OfficeLocation);


$(document).on('ready page:load', function () {
  console.log('dom loaded');

  const element = document.getElementById("app");

  if (element!=null) {
    const props = JSON.parse(element.getAttribute('data'))
    console.log(props)
    var app = new Vue({
    el: '#app',
    data: props
    });
  }
});
