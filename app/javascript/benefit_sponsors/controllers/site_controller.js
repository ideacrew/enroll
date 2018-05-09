// Visit The Stimulus Handbook for more details
// https://stimulusjs.org/handbook/introduction
//
// This example controller works with specially annotated HTML like:
//
// <div data-controller="hello">
//   <h1 data-target="hello.output"></h1>
// </div>

import { Controller } from "stimulus"

export default class SiteController extends Controller {
  static targets = [ "officeLocations", "officeLocation" ]

  addLocation() {
      //clone new location node, unhide remove button, modify name attribute

      // comment out only the line directly below to get the test to pass

      //var newLocation = document.importNode(this.officeLocationTarget, true)
      var siteLocation = document.querySelector('#siteOfficeLocation');
      var cln = siteLocation.cloneNode(true);
      document.querySelector('.js-non-primary').classList.remove('d-none')
      document.querySelectorAll('.js-remove').forEach(function(element) {
        element.remove()
      })

      //comment out the rest of this method to get the test to pass
      cln.querySelectorAll('input').forEach(function(input) {
        var name = input.getAttribute('name').replace('[0]', `[${Date.now()}]`)
        input.setAttribute('name', name)
        input.value = ''
      })

      siteLocation.appendChild(cln)
    }

  removeLocation(event) {
    //remove itself
    event.target.closest('.js-office-location').remove()
  }
}
