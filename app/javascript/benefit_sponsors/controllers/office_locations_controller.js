// Visit The Stimulus Handbook for more details
// https://stimulusjs.org/handbook/introduction
//
// This example controller works with specially annotated HTML like:
//
// <div data-controller="hello">
//   <h1 data-target="hello.output"></h1>
// </div>

import { Controller } from "stimulus"

let alreadyConnected = false;

export default class extends Controller {
  static targets = [ "officeLocations", "officeLocation" ];

  connect() {
    if (this.element.getAttribute('data-controller-connected')) {
      alreadyConnected = true;
    } else {
      this.element.setAttribute('data-controller-connected', 'true');
      document.getElementById('kindSelect')[0].remove();
      document.getElementById('agency_organization_profile_attributes_office_locations_attributes_0_phone_attributes_kind')[0].remove();
    }
    this.officeLocationTargets.forEach(target => {
      target.classList.add("existing-location");
    });
  }

  addLocation(event) {
    const locations = document.querySelectorAll('.js-office-location');
    const lastLocation = locations[locations.length-1];
    let emptyLocation = true;
    lastLocation.querySelectorAll('input').forEach(function(input) {
      if (input.value != "") {
        emptyLocation = false;
        return;
      }
    })
    if (!emptyLocation) {
      event.preventDefault();
      //clone new location node, unhide remove button, modify name attribute
      var newLocation = document.importNode(this.officeLocationTarget, true)
      var totalLocations = document.importNode(this.officeLocationsTarget, true)
      // totalLocationsCount includes currently loaded OL form too
      var totalLocationsCount = totalLocations.querySelectorAll('.ol_title').length;
      delete newLocation.dataset.target;
      newLocation.querySelectorAll('.js-remove').forEach(function(element) {
        element.remove()
      });

      newLocation.classList.add('new-location');

      newLocation.querySelectorAll('.ol_title').forEach(function(element) {
        element.innerHTML = "Office Location"
      });

      newLocation.querySelectorAll('input').forEach(function(input) {
        var name = input.getAttribute('name').replace('[0]', `[${totalLocationsCount}]`);
        input.setAttribute('name', name)
        input.value = ''
      })

      newLocation.querySelector('input[placeholder="ZIP"]').setAttribute('data-action', "");

      newLocation.querySelector(".phone_number7").addEventListener('input', (event) => {
        event.target.value = this.phoneMask(event.target.value);
      });

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

      this.officeLocationsTarget.appendChild(newLocation);
    }
  }

  removeLocation(event) {
    if (!alreadyConnected) {
      event.preventDefault();
      //remove itself
      event.target.closest('.js-office-location').querySelectorAll('input[id="delete_location"]').forEach(function(input) {
        input.setAttribute('value', true)
      })
      $(event.target).closest('.js-office-location').hide();
    }
  }

  phoneMask(phone) {
    return phone.replace(/\D/g, '')
      .replace(/(\d{3})(\d{1,4})/, '$1-$2')
      .replace(/(-\d{4})\d+?$/, '$1');
  }
}
