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
      //need to add id to element to clone in the view for testing purposes
      //jsdom won't select elements based off of data-target

      var siteLocation = document.querySelector('#siteOfficeLocation');
      var newLocation = siteLocation.cloneNode(true);
      document.querySelector('.js-non-primary').classList.remove('d-none')
      document.querySelectorAll('.js-remove').forEach(function(element) {
        element.remove()
      })

      newLocation.querySelectorAll('input').forEach(function(input) {
        var name = input.getAttribute('name').replace('[0]', `[${Date.now()}]`)
        input.setAttribute('name', name)
        input.value = ''
      })

      siteLocation.appendChild(newLocation)
    }

  removeLocation(event) {
    //remove itself
    event.target.closest('.js-office-location').remove()
  }
}
