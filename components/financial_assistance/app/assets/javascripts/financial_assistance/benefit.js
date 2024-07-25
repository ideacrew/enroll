function stopEditingBenefit() {
  $('.driver-question, .instruction-row, .benefit-kind').removeClass('disabled');
  $('input.benefit-checkbox').prop('disabled', false);
  $('a.benefit-edit').removeClass('disabled');
  // $('a.benefit-delete').removeClass('disabled');
  $('.col-md-3 > .interaction-click-control-continue').removeClass('disabled');
};

function startEditingBenefit(benefit_kind) {
  $('.driver-question, .instruction-row, .benefit-kind:not(#' + benefit_kind + ')').addClass('disabled');
  $('input.benefit-checkbox').prop('disabled', true);
  $('a.benefit-edit').addClass('disabled');
  // $('a.benefit-delete').removeClass('disabled');
  $('.col-md-3 > .interaction-click-control-continue').addClass('disabled');
};

function currentlyEditing() {
  return $('.interaction-click-control-continue').hasClass('disabled');
};

function afterDestroyHide(selector_id, kind){
  $(".benefits #"+selector_id+" input[type='checkbox'][value='"+kind+"']").prop('checked', false);
  $(".benefits #"+selector_id+" .add-more-link-"+kind).addClass('hidden');
};

// bs4 code until stop ----------------------------------
// disable and lower the opacity of the form except pertinent sections
function startEditing(parentContainer) {
  $('#nav-buttons a').addClass('disabled');
  $('.driver-question, .instruction-row, .add_new_benefit_kind').addClass('disabled');
  $(parentContainer).removeClass("disabled");
  $(parentContainer).find('.benefit').addClass("disabled");
  $(parentContainer).find('.active').removeClass("disabled");
  $('.driver-question input:not(input[type=submit]), .disabled a').attr('disabled', true);
  $(parentContainer).find('.active input:not([type=submit])').removeAttr('disabled');
  $('.disabled a').attr('tabindex', -1);
  $('.disabled a').addClass('disabled');
};

// re-enable and raise the opacity of the form post editing
function stopEditing() {
  $('#nav-buttons a').removeClass('disabled');
  $('.driver-question, .instruction-row, .add_new_benefit_kind', '.benefit').removeClass('disabled');
  $('.disabled a').removeAttr('tabindex');
  $('.disabled a').removeClass('disabled');
  $('.disabled input:not(input[type=submit]), .disabled a').removeAttr('disabled');
  $('.driver-question input:not(input[type=submit]), .disabled a').removeAttr('disabled');
  $('.driver-question, .instruction-row, .disabled a, .benefits-list, #nav-buttons a, .benefit, .add_new_benefit_kind').removeClass('disabled');
};

// in order to make sure the input ids/labels are unique, we need to add a random string to the end
// so we don't get WAVE errors
function makeInputIdsUnique(formId, clonedForm) {
  const myArray = new Uint32Array(10)
  let newFormId = window.crypto.getRandomValues(myArray)[0]

  clonedForm.querySelectorAll('label').forEach(function(label) {
    var currentFor = label.getAttribute('for');
    if (currentFor === null) {
      return;
    }
    var newFor = currentFor.split("|")[0] + "|"+ newFormId;
    label.setAttribute('for', newFor);
  });
  clonedForm.querySelectorAll('input, select').forEach(function(input) {
    var currentId = input.getAttribute('id');
    if (currentId === null) {
      return;
    }
    var newId = currentId.split("|")[0] + "|"+ newFormId;
    input.setAttribute('id', newId);
  });
}


document.addEventListener("turbolinks:load", function() {

  // if benefits already exist, show them and default to yes
  if ($("#enrolled-benefit-kinds .benefit").length > 0) {
    $('#has_enrolled_health_coverage_true').prop('checked', true).trigger('change');
  } else {
    $('#has_enrolled_health_coverage_true').removeAttr('checked')
  }

  if ($("#eligible-benefit-kinds .benefit").length > 0) {
    $('#has_eligible_health_coverage_true').prop('checked', true).trigger('change');
  } else {
    $('#has_eligible_health_coverage_true').removeAttr('checked');
  }

  // add the new benefit form fields once the insurance kind is selected
  $('.benefit-kinds').off('change', 'select.insurance-kind');
  $('.benefit-kinds').on('change', 'select.insurance-kind', function(event) {
    // get the benefit form for the proper esi kind
    // clone it and append it to the benefit list
    // set the insurance_kind to the insuranceKind
    // and display it

    var select = event.target;
    var selected = select.options[select.selectedIndex];
    if (selected.value !== "") {
    const kind = select.dataset.kind;
    const esi = selected.dataset.esi;
    const mvsq = selected.dataset.mvsq;
    const benefitList = document.querySelector('.benefits-list.' + kind);
    var benefitForm = esi == "true" ? document.getElementById('new-benefit-esi-form-' + kind) : document.getElementById('new-benefit-non-esi-form-' + kind);
    var clonedForm = benefitForm.cloneNode(true);
    document.getElementById('add_new_benefit_kind_' + kind).classList.add('hidden');
    $(clonedForm.querySelector('.insurance-kind-label-container')).html($(document.createElement("h2")).text(selected.innerText.split('$')[0]));
    clonedForm.querySelector('#benefit_insurance_kind').value = selected.value;
    clonedForm.removeAttribute('id');
    clonedForm.classList.remove('hidden');
    clonedForm.classList.add(selected.value);
    clonedForm.classList.add('benefit');
    clonedForm.classList.add('active');
    $(clonedForm).find('input').removeAttr('disabled');
    let formId = clonedForm.querySelector('.benefit-form-container').id
    makeInputIdsUnique(formId, clonedForm)

    // do all the esi specific hiding and showing
    if (esi == "true") {
      // show non-hra questions if non-hra is the selected insurance kind
      // show hra questions if hra is the selected insurance kind
      // make the inputs of the non-selected kind non-reqquired
      // make the inputs of the selected kind required
      if (selected.value !== "health_reimbursement_arrangement") {
        clonedForm.querySelector('.non-hra-questions').classList.remove('hidden');
        clonedForm.querySelectorAll('.non-hra-questions input, non-hra-questions select').forEach(function(input) {
          var label = clonedForm.querySelector("label[for='" + input.id + "']")
          if ((label && label.classList.contains('required')) || input.classList.contains('required')) {
            input.setAttribute('required', true);
          }
        });
        clonedForm.querySelector('.hra-questions').classList.add('hidden');
        clonedForm.querySelectorAll('.hra-questions input, .hra-questions select').forEach(function(input) {
          input.removeAttribute('required');
        });
      } else {
        clonedForm.querySelector('.hra-questions').classList.remove('hidden');
        clonedForm.querySelectorAll('.hra-questions input, hra-questions select').forEach(function(input) {
          var label = clonedForm.querySelector("label[for='" + input.id + "']")
          if ((label && label.classList.contains('required')) || input.classList.contains('required')) {
            input.setAttribute('required', true);
          }
        });
        clonedForm.querySelector('.non-hra-questions').classList.add('hidden');
        clonedForm.querySelectorAll('.non-hra-questions input, .non-hra-questions select').forEach(function(input) {
          input.removeAttribute('required');
        });
      }

      // show mvsq if msqv is true
      if (mvsq === "true") {
        clonedForm.querySelector('.mvsq-questions').classList.remove('hidden');
        clonedForm.querySelectorAll('.mvsq-questions input, mvsq-questions select').forEach(function(input) {
          var label = clonedForm.querySelector("label[for='" + input.id + "']")
          if ((label && label.classList.contains('required')) || input.classList.contains('required')) {
            input.setAttribute('required', true);
          }
        });
      } else {
        clonedForm.querySelector('.mvsq-questions').classList.add('hidden');
        clonedForm.querySelectorAll('.mvsq-questions input, mvsq-questions select').forEach(function(input) {
          input.removeAttribute('required');
        });
      }
    }

    select.closest(".new-benefit-form").classList.add('hidden');
    benefitList.appendChild(clonedForm);
    startEditing(select.closest(".driver-question"));
  }
  });

  // show the field to select the insurance kind when the add new benefit button is clicked
  $('.benefit-kinds').off('click keydown', 'button.add_new_benefit_kind');
  $('.benefit-kinds').on('click keydown', 'button.add_new_benefit_kind', function(event) {
    if (event.type === 'keydown' && event.key !== 'Enter') {
      return;
    }
    var button = event.target;
    var kind = button.dataset.kind;
    button.classList.add('hidden');
    var newBenefitFormEl = document.getElementById('new-benefit-form-' + kind);
    newBenefitFormEl.classList.remove('hidden');
    $(newBenefitFormEl).find('select').prop('selectedIndex', 0);
    //document.getElementById('new-benefit-form-' + kind).querySelectorAll('.benefit-cancel-before-form').classList.remove('hidden')
  });

  // hide the select insurance kind field when the cancel button is clicked
  $('.benefit-kinds').off('click keydown', '.benefit-cancel-before-form');
  $('.benefit-kinds').on('click keydown', '.benefit-cancel-before-form', function(event) {
    if (event.type === 'keydown' && event.key !== 'Enter') {
      return;
    }
    var button = event.target;
    var kind = button.dataset.kind;
    var container = document.getElementById('new-benefit-form-' + kind);
    var benefitList = $(button).parents('.benefit-kinds').find('.benefits-list');
    container.classList.add('hidden');
    if ($(benefitList).find('.benefit').length > 0) {
      document.getElementById('add_new_benefit_kind_' + kind).classList.remove('hidden');
    } else {
      benefitList.hide();
      $('#has_' + (kind == 'is_enrolled' ? 'enrolled' : 'eligible') + '_health_coverage_true').prop('checked', false).trigger('change');
    }
    stopEditing()
  });

  // remove the benefit form when the cancel button is clicked
  $('.benefit-kinds').off('click keydown', 'a.benefit-form-cancel');
  $('.benefit-kinds').on('click keydown', 'a.benefit-form-cancel', function(event) {
    if (event.type === 'keydown' && event.key !== 'Enter') {
      return;
    }
    var button = event.target;
    var kind = button.dataset.kind;
    var container = button.closest('form').closest('div');
    var benefitList = container.closest('.benefits-list');
    container.remove();
    if (benefitList.querySelectorAll('.benefit').length == 0) {
      document.getElementById('new-benefit-form-' + kind).classList.remove('hidden');
      $('select#insurance_kind_' + kind).prop('selectedIndex', 0);
    } else {
      document.getElementById('add_new_benefit_kind_' + kind).classList.remove('hidden');
    }
    benefitList.querySelectorAll('.benefit.active').forEach(function(benefit) {
      benefit.classList.remove('active');
    });
    stopEditing()
  });

  // remove the benefit form and replace with benefit show when the cancel button is clicked
  // while the benefit is being edited
  $('.benefit-kinds').off('click keydown', 'a.benefit-edit-cancel');
  $('.benefit-kinds').on('click keydown', 'a.benefit-edit-cancel', function(event) {
    if (event.type === 'keydown' && event.key !== 'Enter') {
      return;
    }
    var button = event.target;
    var kind = button.dataset.kind;
    var container = button.closest('.benefit');
    var benefitList = container.closest('.benefits-list');
    var show = container.querySelector('.benefit-show');
    var form = container.querySelector('.edit-benefit-form');
    show.classList.remove('hidden');
    form.classList.add('hidden');
    if (benefitList.querySelectorAll('.benefit').length == 0) {
      document.getElementById('new-benefit-form-' + kind).classList.remove('hidden');
    } else {
      document.getElementById('add_new_benefit_kind_' + kind).classList.remove('hidden');
    }
    stopEditing()
  });

  // remove the benefit show and add the benefit form when the edit button is checked
  $('.benefit-kinds').off('click keydown', 'a.edit-benefit');
  $('.benefit-kinds').on('click keydown', 'a.edit-benefit', function(event) {
    if (event.type === 'keydown' && event.key !== 'Enter') {
      return;
    }
    var button = event.target;
    var kind = button.dataset.kind;
    var container = button.closest('.benefit');
    var benefitList = container.closest('.benefits-list');
    var show = container.querySelector('.benefit-show');
    var form = container.querySelector('.edit-benefit-form');
    show.classList.add('hidden');
    form.classList.remove('hidden');
    document.getElementById('new-benefit-form-' + kind).classList.add('hidden');
    document.getElementById('add_new_benefit_kind_' + kind).classList.add('hidden');
    stopEditing()
  });

  // remove the benefit entirely when the delete button is checked
  $('.benefit-kinds').off('click keydown', 'a.delete-benefit');
  $('.benefit-kinds').on('click keydown', 'a.delete-benefit', function(event) {
    if (event.type === 'keydown' && event.key !== 'Enter') {
      return;
    }

    var benefit = $(event.target).parents('.benefit')
    var benefitList = benefit.parents('.benefits-list')[0];
    var url = $(benefit).attr('id').replace('benefit_', 'benefits/');
    var kind = $(event.target).data('kind')

    $(benefit).remove();

    $.ajax({
      type: 'DELETE',
      url: url
    });

    if (benefitList.querySelectorAll('.benefit').length == 0) {
      document.getElementById('new-benefit-form-' + kind).classList.remove('hidden');
      $('select#insurance_kind_' + kind).prop('selectedIndex', 0);
      document.getElementById('add_new_benefit_kind_' + kind).classList.add('hidden');
    } else {
      document.getElementById('add_new_benefit_kind_' + kind).classList.remove('hidden');
    }
    stopEditing()
  });

  // stop bs4 code ----------------------------------
  if ($('.benefit-kinds').length) {
    $(window).bind('beforeunload', function(e) {
      if (!currentlyEditing() || $('#unsavedBenefitChangesWarning:visible').length)
        return undefined;

      (e || window.event).returnValue = 'You have an unsaved benefit, are you sure you want to proceed?'; //Gecko + IE
      return 'You have an unsaved benefit, are you sure you want to proceed?';
    });

    $(document).on('click', 'a[href]:not(.disabled):not(.benefit-support-modal):not([target="_blank"])', function(e) {
      if (currentlyEditing()) {
        e.preventDefault();
        var self = this;

        $('#unsavedBenefitChangesWarning').modal('show');
        $('.btn.btn-danger').click(function() {
          window.location.href = $(self).attr('href');
        });

        return false;
      } else
      return true;
    });

    $(document).on('click', '.benefit-kind input[type="checkbox"]', function(e) {
      var value = e.target.checked,
          self = this;
      if (value) {
        var newBenefitFormEl = $(this).parents('.benefit-kind').children('.new-benefit-form'),
            benefitListEl = $(this).parents('.benefit-kind').find('.benefits-list');
        if (newBenefitFormEl.find('select').data('selectric')) newBenefitFormEl.find('select').selectric('destroy');
        var clonedForm = newBenefitFormEl.clone(true, true)
          .removeClass('hidden')
          .appendTo(benefitListEl);
        startEditingBenefit($(this).parents('.benefit-kind').attr('id'));
        $(clonedForm).find('select').selectric();
        $(clonedForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110"});
        e.stopImmediatePropagation();
      } else {
        // prompt to delete all these benefits
        e.preventDefault();
        // prompt to delete all these dedcutions
        $("#destroyAllBenefits").modal();

        $("#destroyAllBenefits .modal-cancel-button").click(function(e) {
          $("#destroyAllBenefits").modal('hide');
        });

        $("#destroyAllBenefits .modal-continue-button").click(function(e) {
          $("#destroyAllBenefits").modal('hide');
          $(self).prop('checked', false);

          $(self).parents('.benefit-kind').find('.benefits-list > .benefit').each(function(i, benefit) {
            var url = $(benefit).attr('id').replace('benefit_', 'benefits/');
            $(benefit).remove();

            $.ajax({
              type: 'DELETE',
              url: url
            });
          });
        });
      }
    });

    /* Add more benefits */
    $(document).on('click', "#add_new_insurance_kind", function(e){
        $(this).addClass("hidden");
        var newBenefitFormEl = $(this).closest('.benefit-kind').children('.new-benefit-form'),
          benefitListEl = $(this).closest('.benefit-kind').find('.benefits-list');
        if (newBenefitFormEl.find('select').data('selectric')) newBenefitFormEl.find('select').selectric('destroy');
        var clonedForm = newBenefitFormEl.clone(true, true)
          .removeClass('hidden')
          .appendTo(benefitListEl);
          startEditingBenefit($(this).parents('.benefit-kind').attr('id'));
        $(clonedForm).find('select').selectric();
        $(clonedForm).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110"});
        e.stopImmediatePropagation();
    });

    /* edit existing benefits */
    $('.benefit-kinds').on('click', 'a.benefit-edit:not(.disabled)', function(e) {
      e.preventDefault();
      var benefitEl = $(this).parents('.benefit');
      benefitEl.find('.benefit-show').addClass('hidden');
      benefitEl.find('.edit-benefit-form').removeClass('hidden');
      benefitEl.find('select').selectric();
      $(benefitEl).find(".datepicker-js").datepicker({ dateFormat: 'mm/dd/yy', changeMonth: true, changeYear: true, yearRange: "-110:+110"});
      startEditingBenefit($(this).parents('.benefit-kind').attr('id'));
    });


    /* destroy existing benefits */
    $('.benefit-kinds').on('click', 'a.benefit-delete:not(.disabled)', function(e) {
      var self = this;
      e.preventDefault();
      $("#destroyBenefit").modal();

      $("#destroyBenefit .modal-cancel-button").click(function(e) {
        $("#destroyBenefit").modal('hide');
      });

      $("#destroyBenefit .modal-continue-button").click(function(e) {
        $("#destroyBenefit").modal('hide');
        $(self).parents('.benefit').remove();

        var url = $(self).parents('.benefit').attr('id').replace('benefit_', 'benefits/')

        $.ajax({
          type: 'delete',
          url: url
        })
      });
    });

    /* DELETING all enrolled benefits on selcting 'no' on Driver Question */
    $('#has_enrolled_health_coverage_false').on('change', function(e) {
      self = this;
      //$('#DestroyExistingJobIncomesWarning').modal('show');
      if ($('.benefits-list.is_enrolled .benefit').length) {
        e.preventDefault();
        // prompt to delete all these dedcutions
        $("#destroyAllBenefits").modal();

        $("#destroyAllBenefits .modal-cancel-button").click(function(e) {
          $("#destroyAllBenefits").modal('hide');
          $('#has_enrolled_health_coverage_true').prop('checked', true).trigger('change');
        });

        $("#destroyAllBenefits .modal-continue-button").click(function(e) {
          $("#destroyAllBenefits").modal('hide');
          //$(self).prop('checked', false);

          $('.benefits-list.is_enrolled .benefit').each(function(i, benefit) {
            var url = $(benefit).attr('id').replace('benefit_', 'benefits/');
            $(benefit).remove();
            $.ajax({
              type: 'DELETE',
              url: url
            });
          });
        });
      }
    });

    /* DELETING all enrolled benefits on selcting 'no' on Driver Question */
    $('#has_eligible_health_coverage_false').on('change', function(e) {
      self = this;
      if ($('.benefits-list.is_eligible .benefit').length) {
        e.preventDefault();
        // prompt to delete all these dedcutions
        $("#destroyAllBenefits").modal();

        $("#destroyAllBenefits .modal-cancel-button").click(function(e) {
          $("#destroyAllBenefits").modal('hide');
          $('#has_eligible_health_coverage_true').prop('checked', true).trigger('change');
        });

        $("#destroyAllBenefits .modal-continue-button").click(function(e) {
          $("#destroyAllBenefits").modal('hide');
          //$(self).prop('checked', false);

          $('.benefits-list.is_eligible .benefit').each(function(i, benefit) {
            var url = $(benefit).attr('id').replace('benefit_', 'benefits/');
            $(benefit).remove();
            $.ajax({
              type: 'DELETE',
              url: url
            });
          });
        });
      }
    });
    /* cancel benefit edits */
    $('.benefit-kinds').on('click keydown', 'a.benefit-cancel', function(e) {
      // if key pressed is anything but enter, ignore it
      if (e.type === 'keydown' && e.key !== 'Enter') {
        return;
      }

      e.preventDefault();
      stopEditingBenefit();

      var benefitEl = $(this).parents('.benefit');
      if (benefitEl.length) {
        $(this).closest('.benefit-kind').find('a#add_new_insurance_kind').removeClass("hidden");
        benefitEl.find('.benefit-show').removeClass('hidden');
        benefitEl.find('.edit-benefit-form').addClass('hidden');
      } else {
        if (!$(this).parents('.benefits-list').find('div.benefit').length) {
          $(this).parents('.benefit-kind').find('input[type="checkbox"]').prop('checked', false);
          $(this).closest('.benefit-kind').find('a#add_new_insurance_kind').addClass("hidden");
        }else{
          $(this).closest('.benefit-kind').find('a#add_new_insurance_kind').removeClass("hidden");
        }
        $(this).parents('.new-benefit-form').remove();
        $(this).parents('.edit-benefit-form').remove();
      }
    });

    /* Conditional Display Enrolled Benefit Questions */
    if (!$("#has_enrolled_health_coverage_true").is(':checked')) $("#enrolled-benefit-kinds").addClass('hide');
    /* Conditional Display Eligible Benefit Questions */
    if (!$("#has_eligible_health_coverage_true").is(':checked')) $("#eligible-benefit-kinds").addClass('hide');

    /* Conditional Display denied medicaid Question */
    if (!$("#has_eligible_medicaid_cubcare_true").is(':checked')) $("#denied-medicaid").addClass('hide');

    /* Conditional Display eligibility changed Question */
    if (!$("#has_eligible_medicaid_cubcare_false").is(':checked')) $("#eligibility-change-question").addClass('hide');

    /* Conditional Display household income or size changed Question */
    if (!$("#has_eligibility_changed_true").is(':checked')) $("#household-income-size-changed").addClass('hide');

    /* Conditional Display on dependent income  Question */
    if (!$("#has_dependent_with_coverage_true").is(':checked')) $("#denied-job-end-on").addClass('hide');


    $("body").on("change", "#has_eligible_medicaid_cubcare_true", function(){
      if ($('#has_eligible_medicaid_cubcare_true').is(':checked')) {
        $("#denied-medicaid").removeClass('hide');
        $("#eligibility-change-question").addClass('hide');
        $("#household-income-size-changed").addClass('hide');
        $("#medicaid-chip-coverage-last-day").addClass('hide');
      } else{
        $("#denied-medicaid").addClass('hide');
        $("#eligibility-change-question").removeClass('hide');
      }
    });

    $("body").on("change", "#has_eligible_medicaid_cubcare_false", function(){
      if ($('#has_eligible_medicaid_cubcare_false').is(':checked')) {
        $("#eligibility-change-question").removeClass('hide');
        $("#denied-medicaid").addClass('hide');
      } else{
        $("#eligibility-change-question").addClass('hide');
        $("#denied-medicaid").removeClass('hide');
      }
    });

    $("body").on("change", "#has_eligibility_changed_true", function(){
      if ($('#has_eligibility_changed_true').is(':checked')) {
        $("#household-income-size-changed").removeClass('hide');
        $("#medicaid-chip-coverage-last-day").removeClass('hide');
      } else{
        $("#household-income-size-changed").addClass('hide');
        $("#medicaid-chip-coverage-last-day").addClass('hide');
      }
    });

    $("body").on("change", "#has_eligibility_changed_false", function(){
      if ($('#has_eligibility_changed_false').is(':checked')) {
        $("#household-income-size-changed").addClass('hide');
        $("#medicaid-chip-coverage-last-day").addClass('hide');
      } else{
        $("#household-income-size-changed").removeClass('hide');
        $("#medicaid-chip-coverage-last-day").removeClass('hide');
      }
    });

    $("body").on("change", "#has_enrolled_health_coverage_true", function(){
      if ($('#has_enrolled_health_coverage_true').is(':checked')) {
        $("#enrolled-benefit-kinds").removeClass('hide');
        $("#enrolled-benefit-kinds .benefits-list").show();
        if ($("#enrolled-benefit-kinds .benefit").length > 0) {
          $('#add_new_benefit_kind_is_enrolled').removeClass('hidden');
        } else {
          $('#add_new_benefit_kind_is_enrolled').addClass('hidden');
          $("#new-benefit-form-is_enrolled").removeClass('hidden');
          if ($("body").data('bs4')) {
            startEditing($('#has_enrolled_health_coverage_true').closest(".driver-question"));
          }
        }
      } else{
        $("#enrolled-benefit-kinds").addClass('hide');
      }
    });

    $("body").on("change", "#has_enrolled_health_coverage_false", function(){
      if ($('#has_enrolled_health_coverage_false').is(':checked')) {
        $("#enrolled-benefit-kinds").addClass('hide');
      } else{
        $("#enrolled-benefit-kinds").removeClass('hide');
      }
    });

    $("body").on("change", "#has_eligible_health_coverage_true", function(){
      if ($('#has_eligible_health_coverage_true').is(':checked')) {
        $("#eligible-benefit-kinds").removeClass('hide');
        $("#eligible-benefit-kinds .benefits-list").show();
        if ($("#eligible-benefit-kinds .benefit").length > 0) {
          $('#add_new_benefit_kind_is_eligible').removeClass('hidden');
        } else {
          $('#add_new_benefit_kind_is_eligible').addClass('hidden');
          $("#new-benefit-form-is_eligible").removeClass('hidden');
          if ($("body").data('bs4')) {
            startEditing($('#has_eligible_health_coverage_true').closest(".driver-question"));
          }
        }
      } else{
        $("#eligible-benefit-kinds").addClass('hide');
      }
    });

    $("body").on("change", "#has_eligible_health_coverage_false", function(){
      if ($('#has_eligible_health_coverage_false').is(':checked')) {
        $("#eligible-benefit-kinds").addClass('hide');
      } else{
        $("#eligible-benefit-kinds").removeClass('hide');
      }
    });

    /* Condtional Display immigration status changed question */
    if (!$("#medicaid_chip_ineligible_true").is(':checked')) $("#immigration-status-changed-driver").addClass('hide');

    $("body").on("change", "#medicaid_chip_ineligible_true", function(){
      if ($('#medicaid_chip_ineligible_true').is(':checked')) {
        $("#immigration-status-changed-driver").removeClass('hide');
      } else{
        $("#immigration-status-changed-driver").addClass('hide');
      }
    });

    $("body").on("change", "#medicaid_chip_ineligible_false", function(){
      if ($('#medicaid_chip_ineligible_false').is(':checked')) {
        $("#immigration-status-changed-driver").addClass('hide');
      } else{
        $("#immigration-status-changed-driver").removeClass('hide');
      }
    });

    $("body").on("change", "#has_dependent_with_coverage_true", function(){
      if ($('#has_dependent_with_coverage_true').is(':checked')) {
        $("#denied-job-end-on").removeClass('hide');
      } else{
        $("#denied-job-end-on").addClass('hide');
      }
    });

    $("body").on("change", "#has_dependent_with_coverage_false", function(){
      if ($('#has_dependent_with_coverage_false').is(':checked')) {
        $("#denied-job-end-on").addClass('hide');
      } else{
        $("#denied-job-end-on").removeClass('hide');
      }
    });

    /* Saving Responses to Income  Driver Questions */
    $('#has_enrolled_health_coverage_false, #has_eligible_health_coverage_false, #has_enrolled_health_coverage_true, #has_eligible_health_coverage_true, #health_service_through_referral_true, #health_service_through_referral_false, #health_service_eligible_true, #health_service_eligible_false, #has_eligibility_changed_true, #has_eligibility_changed_false, #has_household_income_changed_true, #has_household_income_changed_false, #person_coverage_end_on, #medicaid_cubcare_due_on, #has_dependent_with_coverage_true, #has_dependent_with_coverage_false, #dependent_job_end_on, #medicaid_chip_ineligible_true, #medicaid_chip_ineligible_false, #immigration_status_changed_true, #immigration_status_changed_false').off('change');
    $('#has_enrolled_health_coverage_false, #has_eligible_health_coverage_false, #has_enrolled_health_coverage_true, #has_eligible_health_coverage_true, #health_service_through_referral_true, #health_service_through_referral_false, #health_service_eligible_true, #health_service_eligible_false, #has_eligibility_changed_true, #has_eligibility_changed_false, #has_household_income_changed_true, #has_household_income_changed_false, #person_coverage_end_on, #medicaid_cubcare_due_on, #has_dependent_with_coverage_true, #has_dependent_with_coverage_false, #dependent_job_end_on, #medicaid_chip_ineligible_true, #medicaid_chip_ineligible_false, #immigration_status_changed_true, #immigration_status_changed_false').on('change', function(e) {
      var attributes = {};
      attributes[$(this).attr('name')] = $(this).val();
      $.ajax({
        type: 'POST',
        url: window.location.pathname.replace('/benefits', ''),
        data: { financial_assistance_applicant: attributes },
        success: function(response){
        }
      })
    });

    $('#has_eligible_medicaid_cubcare_true').on('change', function(e) {
      var attributes = {};
      $("#has_eligibility_changed_true, #has_eligibility_changed_false, #has_household_income_changed_true, #has_household_income_changed_false, #person_coverage_end_on").each(function(i, ele) {
         attributes[$(this).attr('name')] = " ";
       });

      attributes[$(this).attr('name')] = $(this).val();

      $("#person_coverage_end_on").val();
      $.ajax({
        type: 'POST',
        url: window.location.pathname.replace('/benefits', ''),
        data: { financial_assistance_applicant: attributes },
        success: function(response){
        }
      })
    });

    $('#has_eligible_medicaid_cubcare_false').on('change', function(e) {
      var attributes = {};
      $("#medicaid_cubcare_due_on").each(function(i, ele) {
         attributes[$(this).attr('name')] = " ";
         $(this).val("");
       });

       attributes[$(this).attr('name')] = $(this).val();

      $.ajax({
        type: 'POST',
        url: window.location.pathname.replace('/benefits', ''),
        data: { financial_assistance_applicant: attributes },
        success: function(Responsesponse){
        }
      })
    });

    $('#has_dependent_with_coverage_true').on('change', function(e) {
      var attributes = {};
      $("#has_dependent_with_coverage_true, #has_dependent_with_coverage_false, #dependent_job_end_on").each(function(i, ele) {
         attributes[$(this).attr('name')] = " ";
          $(this).val("");
       });

      $.ajax({
        type: 'POST',
        url: window.location.pathname.replace('/benefits', ''),
        data: { financial_assistance_applicant: attributes },
        success: function(response){
        }
      })
    });
  }


    $('body').on('keyup keydown keypress', '#benefit_employer_phone_full_phone_number', function (e) {
        $(this).mask('(000) 000-0000');
        return (key == 8 ||
            key == 9 ||
            key == 46 ||
            (key >= 37 && key <= 40) ||
            (key >= 48 && key <= 57) ||
            (key >= 96 && key <= 105) );

    });

    $('body').on('keyup keydown keypress', '#benefit_employer_address_zip', function (e) {
        var key = e.which || e.keyCode || e.charCode;
        $(this).attr('maxlength', '5');
        return (key == 8 ||
            key == 9 ||
            key == 46 ||
            (key >= 37 && key <= 40) ||
            (key >= 48 && key <= 57) ||
            (key >= 96 && key <= 105) );
    });

    $('body').on('keyup keydown keypress', '#benefit_employer_id', function (e) {
        var key = e.which || e.keyCode || e.charCode;
        $(this).mask("00-0000000");
        return (key == 8 ||
            key == 9 ||
            key == 46 ||
            (key >= 37 && key <= 40) ||
            (key >= 48 && key <= 57) ||
            (key >= 96 && key <= 105) );

    });

});
