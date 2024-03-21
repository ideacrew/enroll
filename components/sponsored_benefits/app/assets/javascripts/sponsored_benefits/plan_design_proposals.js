$(document).on('click', '.plan-design .nav-tabs li label', fetchCarriers);
$(document).on('change', '.plan-design .nav-tabs li input', carrierSelected);
$(document).on('slideStop', '#new_forms_plan_design_proposal .benefits-fields .slider', setSliderDisplayVal);
$(document).on('click', '.plan_design_proposals .checkbox', calcPlanDesignContributions);
$(document).on('click', ".plan-design li:has(label.elected_plan)", attachEmployerHealthContributionShowHide);

$(document).on('click', '.reference-plan input[type=checkbox]', comparisonPlans);
$(document).on('click', '#clear-comparison', clearComparisons);
$(document).on('click', '#view-comparison', viewComparisons);
$(document).on('click', '#hide-detail-comparisons', hideDetailComparisons);
$(document).on('click', '.plan-type-filters .plan-search-option', sortPlans);

$(document).on('submit', '#new_forms_plan_design_proposal', preventSubmitPlanDesignProposal);
$(document).on('click', '#AddDentalToPlanDesignProposal', AddDentalToPlanDesignProposal);
$(document).on('click', '#reviewPlanDesignProposal', saveProposalAndNavigateToReview);
$(document).on('click', '#submitPlanDesignProposal', saveProposal);
$(document).on('click', '#copyPlanDesignProposal', saveProposalAndCopy);
$(document).on('click', '#publishPlanDesignProposal', saveProposalAndPublish);

$(document).on('click', '.downloadReferencePlanDetailsButton.plan-not-saved', checkIfSbcIncluded);
$(document).on('click', '.downloadReferencePlanDetailsButton.plan-saved', sendPdf);


$(document).on('ready', pageInit);
$(document).on('turbolinks:load', pageInit);

function pageInit() {
  var kind = fetchBenefitKind();

  if(kind == "dental") {
    var dental_reference_plan_id = $("#dental_reference_plan_id").val();
    if(dental_reference_plan_id != '' && dental_reference_plan_id != undefined) {
      enableRemoveDentalBenefits();
      calcPlanDesignContributions();
    } else {
      disableActionButtons();
      setTimeout(function() {
        $(".plan-design .nav-tabs li label:first").trigger('click');
      },600)
    }
  } else {
    if ($("#reference_plan_id").val() != '') {
      calcPlanDesignContributions();
    } else {
      disableActionButtons();
      setTimeout(function() {
        $(".plan-design .nav-tabs li label:first").trigger('click');
      },600)
    }
    initSlider();
    $('.loading-plans-button').hide();
    disableCompareButton();
  }
}

function attachEmployerHealthContributionShowHide() {
  var offering_id = $(this).attr("data-offering-id");
  var option_kind = $(this).attr("data-offering-kind");
  if (option_kind == "sole_source") {
    $("div[data-offering-target='" + offering_id + "']").removeClass('enabled');
    $("div[data-offering-target='composite_" + offering_id + "']").addClass("enabled");
  } else {
    $("div[data-offering-target='composite_" + offering_id + "']").removeClass("enabled");
    $("div[data-offering-target='" + offering_id + "']").addClass("enabled");
  }
}

function fetchDentalCustom(){
    var plan_design_organization_id = $('#plan_design_organization_id').val();
    var active_year = $("#forms_plan_design_proposal_effective_date").val().substr(0,4);
    var dental_plan_ids = [];
    $.each($("input[name='Dental Plan']:checked"), function(){
        dental_plan_ids.push($(this).val());
    });

    if(!dental_plan_ids.length){
        return alert("Please Select One of Plan Under Custom Carrier Filter");
    }
    $.ajax({
        type: "POST",
        data:{
          active_year: active_year,
          plans_ids: dental_plan_ids,
          kind: "dental"
        },
        success: function() {

        },
        url: "/sponsored_benefits/organizations/plan_design_organizations/" + plan_design_organization_id + "/dental_reference_plans"
    });
}

function fetchCarriers() {
  var active_year = $("#forms_plan_design_proposal_effective_date").val().substr(0,4);
  var selected_carrier_level = $(this).siblings('input').val();
  var plan_design_organization_id = $('#plan_design_organization_id').val();
  var plan_design_proposal_id = $('#plan_design_proposal_id').val();

  var kind = $("#benefits_kind").val();
  $(this).closest('.plan-design').find('.nav-tabs li').removeClass('active');
  $(this).closest('li').addClass('active');
  hideDetailComparisons;
  $.ajax({
    type: "GET",
    data:{
      active_year: active_year,
      selected_carrier_level: selected_carrier_level,
      plan_design_proposal_id: plan_design_proposal_id,
      kind: kind
    },
    success: function() {
      //Do something
    },
    url: "/sponsored_benefits/organizations/plan_design_organizations/" + plan_design_organization_id + "/carriers"
  });

  displayActiveCarriers();
  hidePlanContainer();
  toggleSliders(selected_carrier_level);
  clearComparisons();
}

function setSBC(element, plan) {
  var kind = fetchBenefitKind();
  var sbc_link = element.parentElement.getElementsByClassName("sbc-download-checkbox")[0]

  if (kind == "health" && sbc_link && sbc_link.checked == true) {
   $(element).attr('href',plan+"?sbc_included=true");
  } else {
   $(element).attr('href',plan);
  }
}

function url_redirect(options){
  var $form = $("<form />");
  $form.attr("action",options.url);
  $form.attr("method",options.method);
            
  for (var key in options.data)
    buildChiderenElements($form, key, options.data[key]);
            
  $("body").append($form);
  $form.submit();
}

function buildChiderenElements(form, prefix, data) {
    for (var key in data)
      if (typeof(data[key]) == 'string'){
        form.append("<input type='hidden' name='"+prefix+"["+ key +"]"+"' value='"+ data[key] +"' />");
      }
      else {
        buildChiderenElements(form, prefix+"["+ key +"]", data[key]);
      }
}

function downloadPdf(event, element) {
  event.preventDefault();
  event.stopPropagation();
  var data = buildBenefitGroupParams();
  if(!(data.benefit_group)) {
    data.benefit_group = {
      kind: element.dataset.kind
    }
  }
  url_redirect({url: element.href, method: "post", data: data});
}

function sendPdf(event) {
  $(this).addClass('plan-not-saved');
  $(this).removeClass('plan-saved');
  window.location.href = $(this).attr('href');
}

function checkIfSbcIncluded(event)  {
  var elem_id = $(this).attr('id');
  var obj = $('#'+elem_id);
  if(obj.hasClass('plan-not-saved')) {
      //event.preventDefault();
      var data = buildBenefitGroupParams();
      if (proposalIsInvalid(data)) {
        // handle error messaging
        return;
      } else {
        url = $("#benefit_groups_url").val();
        $.ajax({
          type: "POST",
          data: data,
          url: url
        }).done(function(){
          obj.removeClass('plan-not-saved');
          obj.addClass('plan-saved');
          obj.click();
        });
      }
    }
}

function displayActiveCarriers() {
  $(this).closest('.plan-design').find('.nav-tabs li').removeClass('active');
  $(this).closest('li').addClass('active');
  $(this).closest('.plan-design').find('.nav-tabs li.active label').attr('style', '');
  $(this).closest('.plan-design').find('.nav-tabs li:not(.active) label').css({borderBottom: "none", borderBottomLeftRadius: "0", borderBottomRightRadius: "0" });

  if ($(this).find('input[type=radio]').is(':checked')) {
  } else {
    $(this).closest('.plan-design').find('.plan-options > *').hide();
    $(this).closest('.plan-design').find('.loading-container').html("<div class=\'col-xs-12 loading\'><i class=\'fa fa-spinner fa-spin fa-2x\'></i></div>");
  }
}

function hidePlanContainer() {
  $('.reference-plans').hide();
  $('.selected-plan').html("");
}

function carrierSelected() {
  $('.tab-container').hide();
  var elected_plan_kind = $('.plan-design .nav-tabs li.active input').val();
  selected_rpids = [];
  $('.plan-comparison-container').hide();

  var kind = fetchBenefitKind();
  if (kind == "dental") {
    if(elected_plan_kind == "custom") {
      $("#dental_elected_plan_kind").val("single_plan");
    } else {
      $("#dental_elected_plan_kind").val(elected_plan_kind);
    }
    $("#dental_reference_plan_id").val("");
  }else {
    $("#elected_plan_kind").val(elected_plan_kind);
    $("#reference_plan_id").val("");
  }

  if (elected_plan_kind == "custom") {
    $(this).closest('.plan-design').find('.carrier-custom-plan-tab').show();
    $(this).closest('.plan-design').find('.plan-options').slideDown();
  }

  if (elected_plan_kind == "single_carrier") {
    $(this).closest('.plan-design').find('.carriers-tab').show();
    $(this).closest('.plan-design').find('.plan-options').slideDown();
  }
  else if (elected_plan_kind == "metal_level") {
    $(this).closest('.plan-design').find('.metals-tab').show();
    $(this).closest('.plan-design').find('.plan-options').slideDown();
  }
  else if (elected_plan_kind == "single_plan") {
    $(this).closest('.plan-design').find('.single-plan-tab').show();
    $(this).closest('.plan-design').find('.plan-options').slideDown();
  }
  else if (elected_plan_kind == 'sole_source') {
    $(this).closest('.plan-design').find('.sole-source-plan-tab').show();
    $(this).closest('.plan-design').find('.plan-options').slideDown();
  }
}

function setMyPlans(element) {
  // Need to remove jQuery Selectors

  var reference_plan_id = element.dataset.planid.replace(/['"]+/g, '');
  var kind = fetchBenefitKind();

  var plan_option_kind = $("#elected_plan_kind").val();
  if(kind == "dental") {
    var plan_option_kind = $("#dental_elected_plan_kind").val();
  }

  toggleSliders(plan_option_kind);

  if (kind == "dental") {
    document.getElementById('dental_reference_plan_id').value = reference_plan_id;
  }else {
    document.getElementById('reference_plan_id').value = reference_plan_id;
  }

  $(this).closest('.benefit-group-fields').find('.plan-design .selected-plan').html("<br/><br/><div class=\'col-xs-12\'><i class=\'fa fa-spinner fa-spin fa-2x\'></i><h4 style='text-align: center;'>Loading your reference plan preview...</h4></div>");

  if (reference_plan_id != "" && reference_plan_id != undefined){
    $('.plan-design .selected-plan').show();
    calcPlanDesignContributions();
  };
}

function setSliderDisplayVal(slideEvt) {
  slideEvt.preventDefault();
  slideEvt.stopImmediatePropagation();
  $(this).closest('.form-group').find('.hidden-param').val(slideEvt.value).attr('value', slideEvt.value);
  $(this).closest('.form-group').find('.slide-label').text(slideEvt.value + "%");
  calcPlanDesignContributions();
}

function updateSlider(element) {
  var value = element.value;
  var inputBox = $(element).closest('.row').find('input.contribution_handler').val(element.value);
  var slideLabel = $(element).closest('.row').find('.slide-label').text(element.value + "%");
  var slideLabel = $(element).closest('.row').find('.slide-label').text(element.value + "%");
  updateTooltip(element);
}

function updateSliderValue(element) {
  var value = element.value;
  var slider = $(element).closest('.row').find('.contribution_slide_handler').val(element.value);
  var slideLabel = $(element).closest('.row').find('.slide-label').text(element.value + "%");
}

function updateTooltip(element) {
  setTimeout(function() {
    $(element).attr('data-original-title','Contribution Percentage: '+element.value+'%').tooltip('show');
  },400);
}

function toggleSliders(plan_kind) {
  if (plan_kind == 'sole_source') {
    $('.composite-offerings').removeClass('hidden');
    $('.offerings').addClass('hidden');
  } else {
    $('.offerings').removeClass('hidden');
    $('.composite-offerings').addClass('hidden');
  }
}

function calcPlanDesignContributions() {
  data = buildBenefitGroupParams();
  if (proposalIsInvalid(data)) {
    disableActionButtons();
  } else {
    enableActionButtons();
  }

  if (data == undefined || data == {} || !('benefit_group' in data)) {
    return;
  }

  var url = $("#contribution_url").val();

  $.ajax({
    type: "GET",
    url: url,
    dataType: 'script',
    data: data
  }).done(function() {
    // do something on completion?
  });

}

function fetchBenefitKind() {
  if(window.location.href.indexOf("kind=dental") > -1) {
    return "dental"
  } else {
    return "health"
  }
}

function buildBenefitGroupParams() {
  // var kind = $("#benefit_kind").val();
  var kind = fetchBenefitKind();
  var reference_plan_id = $('#reference_plan_id').val();

  if(kind == "dental") {
    var reference_plan_id = $("#dental_reference_plan_id").val();
  }

  // var dental_reference_plan_id = $('#dental_reference_plan_id').val();
  if (reference_plan_id == "" || reference_plan_id == undefined) {
    return {};
  }

  var plan_option_kind = $("#elected_plan_kind").val();

  if(kind == "dental") {
    var plan_option_kind = $("#dental_elected_plan_kind").val();
  }

  var premium_pcts = $('.enabled .benefits-fields input.hidden-param').map(function() {
    return $(this).val();
  }).get();
  var is_offered = $('.enabled .benefits-fields .checkbox label > input[type=checkbox]').map(function() {
    return $(this).is(":checked");
  }).get();

  var composite_rating_tier_types = [ 'employee_only', 'family', 'employee_and_spouse', 'employee_and_one_or_more_dependents']
  var relationship_benefit_types = [ 'employee', 'spouse', 'domestic_partner', 'child_under_26', 'child_26_and_over']
  relation_benefits = {};

  if (plan_option_kind === 'sole_source') {
    premium_pcts.push(premium_pcts[premium_pcts.length - 1]);
    premium_pcts.push(premium_pcts[premium_pcts.length - 1]);

    composite_rating_tier_types.forEach(function(compositeTierType, index, composite_tier_types) {
      relation_benefits[index] = {
        "composite_rating_tier": compositeTierType,
        "employer_contribution_percent": premium_pcts[index],
        "offered":  is_offered[index]
      }
    });
  } else {
    relationship_benefit_types.forEach(function(relationshipType, index, relationships) {
      relation_benefits[index] = {
        "relationship": relationshipType,
        "premium_pct": premium_pcts[index],
        "offered":  is_offered[index]
      }
    });
  }

  var data = {
    'profile_id': $("#profile_id").val(),
    'benefit_group': {
      "reference_plan_id": reference_plan_id,
      "plan_option_kind": plan_option_kind,
      "kind": kind
    }
  }

  var elected_dental_plans = $("#elected_dental_plans").val()
  if(elected_dental_plans) {
    data['benefit_group']['elected_dental_plans'] = elected_dental_plans
  }

  if(plan_option_kind == 'sole_source') {
    data['benefit_group']["composite_tier_contributions_attributes"] = relation_benefits;
  } else {
    data['benefit_group']["relationship_benefits_attributes"] = relation_benefits;
  }
  return data;
}

function initSlider() {
  $('.benefits-fields input.hidden-param, .dental-benefits-fields input.hidden-param').each(function() {
    $(this).closest('.form-group').find('.slider').attr('data-slider-value', $(this).val());
    $(this).closest('.form-group').find('.slide-label').html($(this).val()+"%");
  });

  $('.benefits-fields .slider').bootstrapSlider({
    formatter: function(value) {
      return 'Contribution Percentage: ' + value + '%';
    },
    max: 100,
    min: 0,
    step: 1
  });
}

function setRadioBtn(element) {
  dotIcons = document.querySelectorAll('.fa-dot-circle');
  icons = document.querySelectorAll('.fa-circle');
  iconId = element.target.dataset.tempId;

  dotIcons.forEach(function(icon) {
    icon.classList.add('fa-circle')
  });

  icons.forEach(function(icon) {
    if (icon.dataset.tempId == iconId) {
      icon.classList.add('fa-dot-circle')
    }
  });
}

function preventSubmitPlanDesignProposal(event) {
  event.preventDefault();
}

function disableActionButtons() {
  var minimum_employee_contribution = $("#employer_min_employee_contribution").val();
  var minimum_family_contribution = $("#employer_min_family_contribution").val();
  data = buildBenefitGroupParams();
  if (proposalIsInvalid(data)){
    $(function () {
      $('[data-toggle="tooltip"]').tooltip()
    });
    $('.plan_design_proposals .save-action').prop('disabled', true);
    $('.plan_design_proposals .plan-selection-button-group').attr({
     'data-toggle': "tooltip",
     'data-placement': "top",
      'data-title': fetch_data_title(minimum_employee_contribution, minimum_family_contribution)
   })
  }
}

function fetch_data_title(min_employee_contribution, minimum_family_contribution) {
  /* when it runs first time but did not load minimum_employee_contribution hidden_filed_tag page yet */
  if (typeof min_employee_contribution === "undefined"){
    return "";
  }

  if (minimum_family_contribution === "0"){
    return "Employer premium contribution for Employee Only Health Plans must be at least " + min_employee_contribution + "%"
  } else {
    return "Employer premium contribution for Family Health Plans must be at least " + minimum_family_contribution + "%, and Employee Only Health Plans must be at least " + min_employee_contribution + "%";
  }
}

function enableActionButtons() {
  $('.plan_design_proposals .save-action').removeAttr('disabled');
}

function contributionLevelsAreValid(benefit_group) {
  if ('composite_tier_contributions_attributes' in benefit_group) {
    var contributions = benefit_group['composite_tier_contributions_attributes'];
    return checkContributionLevels(Object.values(contributions));
  } else if ('relationship_benefits_attributes' in benefit_group) {
    var contributions = benefit_group['relationship_benefits_attributes'];
    return checkContributionLevels(Object.values(contributions));
  } else {
    return false;
  }
}

function checkContributionLevels(contributions) {
  var minimum_employee_contribution = $("#employer_min_employee_contribution").val();
  var minimum_family_contribution = $("#employer_min_family_contribution").val();
  var offered_contributions = contributions.filter(function( obj ) {
    return obj.offered;
  });

  values_to_check = offered_contributions.map(function(obj) {
    if('composite_rating_tier' in obj) {
      obj.relationship = obj.composite_rating_tier;
      obj.premium_pct = obj.employer_contribution_percent;
    }
    return obj;
  });
  var contributions_are_valid = [];

  values_to_check.forEach(function(contribution){
    if(contribution.relationship == 'employee' || contribution.relationship == 'employee_only') {
      contributions_are_valid.push((parseInt(contribution.premium_pct) >= parseInt(minimum_employee_contribution)));
    } else if (contribution.relationship == 'family'){
      contributions_are_valid.push((parseInt(contribution.premium_pct) >= parseInt(minimum_family_contribution)));
    } else if (contribution.relationship == 'spouse'){
      contributions_are_valid.push((parseInt(contribution.premium_pct) >= parseInt(minimum_family_contribution)));
    } else if (contribution.relationship == 'domestic_partner'){
      contributions_are_valid.push((parseInt(contribution.premium_pct) >= parseInt(minimum_family_contribution)));
    } else if (contribution.relationship == 'child_under_26'){
      contributions_are_valid.push((parseInt(contribution.premium_pct) >= parseInt(minimum_family_contribution)));
    }
  });
  return contributions_are_valid.every(function(val) {
    return val == true;
  });
}

function enableRemoveDentalBenefits(){
  document.getElementById("removeDentalBenefits").classList.remove('hidden')
}

function proposalIsInvalid(data) {
  if (data == undefined || data == {} || !('benefit_group' in data)) {
    return true;
  } else {
    kind = fetchBenefitKind();
    if(kind == "dental") {
      return false;
    }
    return !contributionLevelsAreValid(data['benefit_group']);
  }
}

function saveProposal(event) {
  var data = buildBenefitGroupParams();
  if (proposalIsInvalid(data)) {
    // handle error messaging
    return;
  } else {
    url = $("#benefit_groups_url").val();
    $.ajax({
      type: "POST",
      data: data,
      url: url
    }).done(function(){
      $('.success-message').html('Plan successfully updated!');
      kind = fetchBenefitKind();
      if(kind == "dental") {
        enableRemoveDentalBenefits();
      }
    });
  }

}

function saveProposalAndCopy(event) {
  event.preventDefault();
  event.stopImmediatePropagation();
  var data = buildBenefitGroupParams();
  if (proposalIsInvalid(data)) {

  } else {
    url = $("#benefit_groups_url").val();
    $.ajax({
      type: "POST",
      data: data,
      url: url
    }).done(function(data) {
      var copy_url = $('#copy_proposal_url').val();
      $.ajax({
        url: copy_url,
        type: 'POST',
        data: {
          profile_id: $("#profile_id").val()
        },
        dataType: 'json',
        success: function(data) {
          window.location.href = data.url + "&profile_id=" + $("#profile_id").val();
        },
        error: function(data) {
          resp = $.parseJSON(data.responseText);
        }
      });
    });
  }
}

function saveProposalAndPublish(event) {
  event.preventDefault();
  event.stopImmediatePropagation();
  data = buildBenefitGroupParams();
  if (!proposalIsInvalid(data)) {
    var url = $("#benefit_groups_url").val();
    $.ajax({
      type: "POST",
      data: data,
      url: url
    }).done(function(data) {
      var publish_url = $('#publish_proposal_url').val();
      $.ajax({
        dataType: 'json',
        url: publish_url,
        type: 'POST',
        data: {
          profile_id: $("#profile_id").val()
        },
        success: function(data) {
          window.location.href = data.url + "&profile_id=" + $("#profile_id").val();
        },
        error: function(data) {
          console.log("error fetching proposal url: " + data.url);
          var assembled_url = data.url + "&profile_id=" + $("#profile_id").val();
          window.location.replace(assembled_url)
        }
      });
    });
  }
}

function AddDentalToPlanDesignProposal(event) {
  event.preventDefault();
  event.stopImmediatePropagation();

  var data = buildBenefitGroupParams();
  if (proposalIsInvalid(data)) {
  } else {
    url = $("#benefit_groups_url").val();
    $.ajax({
      type: "POST",
      data: data,
      url: url
    }).done(function(){
      var url = $("#add_dental_url").val()
      window.location.href = url + "&profile_id=" + $("#profile_id").val()
    });
  }
}

function saveProposalAndNavigateToReview(event) {
  event.preventDefault();
  event.stopImmediatePropagation();
  var data = buildBenefitGroupParams();
  if (proposalIsInvalid(data)) {

  } else {
    var url = $("#benefit_groups_url").val();
    $.ajax({
      type: "POST",
      data: data,
      url: url
    }).done(function(data) {
      window.location.href = data.url + "&profile_id=" + $("#profile_id").val();
    });
  }
}

selected_rpids = [];

function comparisonPlans() {
  $(this).each(function() {
    var value = $(this).val();
    if ($(this).is(":checked") && $.unique(selected_rpids).length <= 3) {
      selected_rpids.push(value)
    }
    if (!$(this).is(":checked")) {
      removeA($.unique(selected_rpids), value);
    }
    if ($.unique(selected_rpids).length > 3) {
      alert("You can only compare up to 3 plans");
      $(this).attr('checked', false);
      removeA($.unique(selected_rpids), value);
    }
  });
  disableCompareButton();
}

function viewComparisons() {
  var url = $("#plan_comparison_url").val();
  $('.view-plans-button').hide();
  $('.loading-plans-button').show();

    $.ajax({
      type: "GET",
      url: url,
      dataType: 'script',
      data: { plans: selected_rpids, sort_by: '' },
    }).done(function() {
      $('#compare_plans_table').dragtable({dragaccept: '.movable'});
      $('.view-plans-button').show();
      $('.loading-plans-button').hide();
    });

    $('.plan-comparison-container').show();
}

function clearComparisons() {
  $('.reference-plan').each(function() {
    var checkboxes = $(this).find('input[type=checkbox]');
    checkboxes.attr('checked', false);
    removeA($.unique(selected_rpids), checkboxes.val());
    disableCompareButton();
  });
}

function hideDetailComparisons() {
  $('.plan-comparison-container').hide();
}

function disableCompareButton() {
  $('#view-comparison').addClass('disabled');
  $('#clear-comparison').addClass('disabled');
  $('.reference-plan input[type=checkbox]').each(function() {
    if ($(this).is(":checked")) {
      $('#view-comparison').removeClass('disabled');
      $('#clear-comparison').removeClass('disabled');
    }
  });
}

function removeA(arr) {
    var what, a = arguments, L = a.length, ax;
    while (L > 1 && arr.length) {
        what = a[--L];
        while ((ax= arr.indexOf(what)) !== -1) {
            arr.splice(ax, 1);
        }
    }
    return arr;
}

function sortPlans() {
  var $box = $(this).children('input').first();

  if ($box.is(":checked")) {
    // the name of the box is retrieved using the .attr() method
    // as it is assumed and expected to be immutable
    var group = "input:checkbox[data-search-type='" + $box.data("search-type") + "']";
    // the checked state of the group/box on the other hand will change
    // and the current value is retrieved using .prop() method
    $(group).prop("checked", false);
    $box.prop("checked", true);
  } else {
    $box.prop("checked", false);
  }

  var plans = $('.reference-plan');
  var search_types = {};

  $('.plan-search-option input').each(function(index) {
    var option = $(this);
    var option_is_checked = option.prop('checked');
    if (option_is_checked) {
      search_types[option.data('search-type').replace(/_/,'-')] = option.val();
    }
  });
  plans.parent().removeClass('hidden');
  plans.each(function(index) {
    var plan = $(this);
    var plan_matches = [];
    Object.keys(search_types).forEach(function(item) {
      var plan_value = plan.data(item);
      plan_matches.push((search_types[item].toString() === plan_value.toString()));
    });
    if(plan_matches.every(function(option){ return option; })) {
    } else {
      plan.parent().addClass('hidden');
    }
  });
}

function setCarrierRadio(element) {
  element.checked = true;
}

function handleReferencePlanSelection(element) {
  if($(".reference-plans").children().length) {
    target = $("input#reference_plan_" + element.value)
    if(element.checked) {
      target.parents('div.reference-plan').show();
    } else {
      if(target.prop('checked')) {
        target.prop('checked', false);
        $("#dental_reference_plan_id").val('')
      }
      target.parents('div.reference-plan').hide();
      disableActionButtons();
    }
  }
}
