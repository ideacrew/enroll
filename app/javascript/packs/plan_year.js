document.addEventListener("DOMContentLoaded", function() {
  // Disable selectric
  var disableSelectric = false;

  var add_plan_year_button = document.getElementById('submitBenefitPackage');
  // Disable with bootstrap disabled (rather than disabled = true)
  // on page load REFS: https://stackoverflow.com/a/46389727/5331859
  add_plan_year_button.classList.add('disabled');

  // Originally embedded ruby as JS, rendered as string with hidden_field_tag
  var disable_benefit_package_buttons_boolean = document.getElementById('disable_benefit_package_buttons_boolean').value;
  if (disable_benefit_package_buttons_boolean == true || disable_benefit_package_buttons_boolean == 'true') {
    // From app/views/ui-components/v1/cards/_metal_level_select.html.slim:
    disableNewAddBenefitPackageButton();
    disableDentalBenefitPackage();
  }
  // Attach validation on form change
  // Benefit package titles originally embedded ruby as JS, rendered as string with hidden_field_tag
  var previous_benefit_package_titles = document.getElementById('previous_benefit_package_titles').value;
  function validateTitle() {
    var new_title = document.getElementById("benefitPackageTitle").value;
    previousBPTitles = previous_benefit_package_titles;

    // TODO: Deprecate this Jquery
    // Original code was this:
    $('[data-toggle="tooltip"]').tooltip();
    // TOOD: Does not seem to work as vanilla JS like so:
    // var tooltips = document.querySelectorAll('[data-toggle]')
    // if (tooltips != null) {
    //  for (i = 0; i < tooltips.length; i++) {
        // TODO: Tooltip is jquery function? Need to figure out native javascript method
        //tooltips[i].tooltip();
    //  }
    // }

    if (previousBPTitles.includes(new_title)) {
      add_plan_year_button.classList.add('disabled');
      document.getElementById('benefitPackageTitle').setAttribute('data-original-title', 'Before you can save, each benefit group must have a unique title.');
    }
    else {
      var benefit_properties_elements = document.querySelectorAll('.benefit-properties span.tool-tip');
      if (benefit_properties_elements != null) {
        for (i =0; i < benefit_properties_elements.length; i++) {
          benefit_properties_elements[i].setAttribute('data-original-title', '');
        }
      }
      add_plan_year_button.classList.remove('disabled');
    }
    // From app/views/ui-components/v1/cards/_metal_level_select.html.slim:
    disableNewPlanYearButton();
  }
});