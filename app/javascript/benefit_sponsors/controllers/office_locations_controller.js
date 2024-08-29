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
let bs4 = document?.documentElement?.dataset?.bs4;

export default class extends Controller {
  static targets = [ "officeLocations", "officeLocation" ];

  connect() {
    if (this.element.getAttribute('data-controller-connected')) {
      alreadyConnected = true;
    } else { 
      this.element.setAttribute('data-controller-connected', 'true');
      if (bs4 != "true") {
        document.getElementById('kindSelect')[0].remove();
        document.getElementById('agency_organization_profile_attributes_office_locations_attributes_0_phone_attributes_kind')[0].remove();
      }
    }
    this.officeLocationTargets.forEach(target => {
      target.classList.add("existing-location");
    });
  }

  addLocation(event) {
    event.preventDefault(); // call is made from a tag w/no href
    if (bs4 == "true") event.stopImmediatePropagation();
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
      var newLocation = document.importNode(this.officeLocationTarget, true);
      var totalLocations = document.importNode(this.officeLocationsTarget, true);
      // totalLocationsCount includes currently loaded OL form too
      var totalLocationsCount = totalLocations.querySelectorAll('.ol_title').length;
      delete newLocation.dataset.target;
      newLocation.querySelectorAll('.js-remove').forEach(function(element) {
        element.remove();
      });

      newLocation.classList.add('new-location');
      newLocation.classList.remove('existing-location');

      newLocation.querySelectorAll('.ol_title').forEach(function(element) {
        element.innerHTML = "Office Location"
      });

      newLocation.querySelectorAll('input').forEach(function(input) {

        var name = input.getAttribute('name').replace('[0]', `[${totalLocationsCount}]`);
        input.setAttribute('name', name);
        input.setAttribute('id', name);
        if (input?.previousElementSibling) input.previousElementSibling.setAttribute('for', name);

        if (bs4 == "true" && input.id == "phoneType") {
          input.value = "work";
        } else {
          input.value = '';
        }
      })

      if (bs4 == "true") {
        var removeButton = newLocation.querySelector('a.remove_fields');
        removeButton.classList.remove('hidden');
        var removeButtonId = "remove-button-" + totalLocationsCount;
        removeButton.id = removeButtonId;
        removeButton.setAttribute('onkeydown', `handleButtonKeyDown(event, '${removeButtonId}')`);
        newLocation.querySelector('input[placeholder="00000"]').setAttribute('data-action', "");
        newLocation.querySelector(".phone_number").addEventListener('input', (event) => {
          event.target.value = this.fullPhoneMask(event.target.value);
        });
      } else {
        newLocation.querySelector('input[placeholder="ZIP"]').setAttribute('data-action', "");
        newLocation.querySelector(".phone_number7").addEventListener('input', (event) => {
          event.target.value = this.phoneMask(event.target.value);
        });
      }

      newLocation.querySelectorAll('select').forEach(function(input) {
        var name = input.getAttribute('name').replace('[0]', `[${totalLocationsCount}]`);
        input.setAttribute('name', name);
        input.setAttribute('id', name);
        input.previousElementSibling.setAttribute('for', name);

        if (input.value != "work" && input.id != "kindSelect") {
          input.value = '';
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
      
      // if .new-location is present, remove it
      // else hide the .existing-location and mark it for deletion
      let location = event.target.closest('.js-office-location');
      if (bs4 == "true" && location.classList.contains('new-location')) {
        location.remove();
      } else {
        $(event.target).closest('.js-office-location').hide();
      }
    }
  }

  phoneMask(phone) {
    return phone.replace(/\D/g, '')
      .replace(/(\d{3})(\d{1,4})/, '$1-$2')
      .replace(/(-\d{4})\d+?$/, '$1');
  }

  fullPhoneMask(phone) {
    let masked = phone.replace(/\D/g, '').match(/(\d{0,3})(\d{0,3})(\d{0,4})/);
    let value = !masked[2] ? masked[1] : '(' + masked[1] + ') ' + masked[2] + (masked[3] ? '-' + masked[3] : '');
    return value;
  }
}