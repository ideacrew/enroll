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
  static targets = [ "officeLocations", "officeLocation" ];

  connect() {
    // Remove space in primary select option and phone option
    document.getElementById('kindSelect')[0].remove();
    document.getElementById('agency_organization_profile_attributes_office_locations_attributes_0_phone_attributes_kind')[0].remove();
  }

  addLocation() {
      event.preventDefault();
    //clone new location node, unhide remove button, modify name attribute
    var newLocation = document.importNode(this.officeLocationTarget, true)
    var totalLocations = document.importNode(this.officeLocationsTarget, true)
    // totalLocationsCount includes currently loaded OL form too
    var totalLocationsCount = totalLocations.querySelectorAll('.ol_title').length;
    newLocation.querySelectorAll('.js-remove').forEach(function(element) {
      element.remove()
    });

    newLocation.querySelectorAll('.ol_title').forEach(function(element) {
      element.innerHTML = "Office Location"
    });

    newLocation.querySelectorAll('input').forEach(function(input) {
      var name = input.getAttribute('name').replace('[0]', `[${totalLocationsCount}]`);
      input.setAttribute('name', name)
      input.value = ''
    })

    newLocation.querySelector('input[placeholder="ZIP"]').setAttribute('data-action', "")

    newLocation.querySelectorAll('select').forEach(function(input) {
      var name = input.getAttribute('name').replace('[0]', `[${totalLocationsCount}]`);
      input.setAttribute('name', name)

      if (input.value != "work" && input.id != "kindSelect") {
        input.value = ''
      }

      if (input.id == "kindSelect") {
        input[0].remove();
      }

    })

    this.officeLocationsTarget.appendChild(newLocation)
  }

  removeLocation(event) {
    event.preventDefault();
    //remove itself
    event.target.closest('.js-office-location').querySelectorAll('input[id="delete_location"]').forEach(function(input) {
      input.setAttribute('value', true)
    })
    $(event.target).closest('.js-office-location').hide();
  }
}
