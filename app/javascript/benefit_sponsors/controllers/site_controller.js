// Visit The Stimulus Handbook for more details
// https://stimulusjs.org/handbook/introduction
//
// This example controller works with specially annotated HTML like:
//
// <div data-controller="hello">
//   <h1 data-target="hello.output"></h1>
// </div>

import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "officeLocations", "officeLocation" ]

  addLocation() {
    //clone new location node, unhide remove button, modify name attribute
    var newLocation = document.importNode(this.officeLocationTarget, true)
    newLocation.querySelector('.js-non-primary').classList.remove('d-none')
    newLocation.querySelectorAll('.js-remove').forEach(function(element) {
      element.remove()
    })
    newLocation.querySelectorAll('input').forEach(function(input) {
      var name = input.getAttribute('name').replace('[0]', `[${Date.now()}]`)
      input.setAttribute('name', name)
      input.value = ''
    })

    this.officeLocationsTarget.appendChild(newLocation)
  }

  removeLocation(event) {
    //remove itself
    event.target.closest('.js-office-location').remove()
  }
}
