$(document).on('ready', initSlider);
$(document).on('click', '.health-plan-design .nav-tabs li label', fetchCarriers);
$(document).on('change', '.health-plan-design .nav-tabs li input', carrierSelected);
$(document).on('click', '.reference-plan input[type=radio] + label', planSelected);
$(document).on('slideStop', '.quote-setup-tab .benefits-fields .slider', setSliderDisplayVal);
$(document).on('change', '.quote-setup-tab input.premium-storage-input', reconcileSliderAndInputVal);
$(document).on('click', ".health-plan-design li:has(label.elected_plan)", attachEmployerHealthContributionShowHide);

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

function fetchCarriers() {
  var active_year = $("#forms_plan_design_proposal_effective_date").val().substr(0,4);
  var selected_carrier_level = $(this).siblings('input').val();
  var plan_design_organization_id = $('#plan_design_organization_id').val();
  $(this).closest('.health-plan-design').find('.nav-tabs li').removeClass('active');
  $(this).closest('li').addClass('active');

  $.ajax({
    type: "GET",
    data:{
      active_year: active_year,
      selected_carrier_level: selected_carrier_level,
    },
    success: function() {
      setTimeout(function() {
        formatRadioButtons()
      },400);
    },
    url: "/sponsored_benefits/organizations/plan_design_organizations/" + plan_design_organization_id + "/carriers"
  });

  displayActiveCarriers();
  hidePlanContainer();
  toggleSliders(selected_carrier_level);
}

function displayActiveCarriers() {
  $(this).closest('.health-plan-design').find('.nav-tabs li').removeClass('active');
  $(this).closest('li').addClass('active');

  $(this).closest('.health-plan-design').find('.nav-tabs li.active label').attr('style', '');
  $(this).closest('.health-plan-design').find('.nav-tabs li:not(.active) label').css({borderBottom: "none", borderBottomLeftRadius: "0", borderBottomRightRadius: "0" });

  if ($(this).find('input[type=radio]').is(':checked')) {
  } else {
    $(this).find('input[type=radio]').prop('checked', true );
    $(this).closest('.health-plan-design').find('.plan-options > *').hide();
    $(this).closest('.health-plan-design').find('.loading-container').html("<div class=\'col-xs-12 loading\'><i class=\'fa fa-spinner fa-spin fa-2x\'></i></div>");
  }
}

function hidePlanContainer() {
  $('.reference-plans').hide();
  $('.selected-plan').html("");
}

function carrierSelected() {
  $('.tab-container').hide();
  var elected_plan_kind = $(this).attr('value');

  $("#elected_plan_kind").val(elected_plan_kind);

  if (elected_plan_kind == "single_carrier") {
    $(this).closest('.health-plan-design').find('.carriers-tab').show();
    $(this).closest('.health-plan-design').find('.plan-options').slideDown();
  }
  else if (elected_plan_kind == "metal_level") {
    $(this).closest('.health-plan-design').find('.metals-tab').show();
    $(this).closest('.health-plan-design').find('.plan-options').slideDown();
  }
  else if (elected_plan_kind == "single_plan") {
    $(this).closest('.health-plan-design').find('.single-plan-tab').show();
    $(this).closest('.health-plan-design').find('.plan-options').slideDown();
  }
  else if (elected_plan_kind == 'sole_source') {
    $(this).closest('.health-plan-design').find('.sole-source-plan-tab').show();
    $(this).closest('.health-plan-design').find('.plan-options').slideDown();
  }
}

function planSelected() {
  
  toggleSliders($("#elected_plan_kind").val());

  var reference_plan_id = $(this).closest('.health-plan-design .reference-plan').find('input').attr('value');
  $("#reference_plan_id").val(reference_plan_id);
  $(this).closest('.benefit-group-fields').find('.health-plan-design .selected-plan').html("<br/><br/><div class=\'col-xs-12\'><i class=\'fa fa-spinner fa-spin fa-2x\'></i><h4 style='text-align: center;'>Loading your reference plan preview...</h4></div>");

  if (reference_plan_id != "" && reference_plan_id != undefined){
    $('.health-plan-design .selected-plan').show();
    calcEmployerContributions();
  };
}

function reconcileSliderAndInputVal() {
  if ( $(this).hasClass('hidden-param') )  {
    var hidden = parseInt($(this).val());
    if (hidden < 0) {
      hidden = 0;
    } else if (hidden > 100) {
      hidden = 100;
    }
    var mySlider = $(this).closest('.form-group').find('input.slider');
    mySlider.bootstrapSlider('setValue', hidden);
    $(this).closest('.form-group').find('input.slider').attr('value', hidden).attr('data-slider-value', hidden);
    $(this).closest('.form-group').find('.slide-label').text(hidden + "%");
    $(this).val(hidden);
  }
}

function setSliderDisplayVal(slideEvt) {
  $(this).closest('.form-group').find('.hidden-param').val(slideEvt.value).attr('value', slideEvt.value);
  $(this).closest('.form-group').find('.slide-label').text(slideEvt.value + "%");
  calcEmployerContributions();

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

function calcEmployerContributions() {
  var reference_plan_id = $('#reference_plan_id').val();
  var plan_option_kind = $("#elected_plan_kind").val();
  var url = $("#contribution_url").val();

  var premium_pcts = $('.enabled .benefits-fields input.hidden-param').map(function() {
    return $(this).val();
  }).get();
  var is_offered = $('.enabled .benefits-fields .checkbox label > input[type=checkbox]').map(function() {
    return $(this).is(":checked");
  }).get();

  if (reference_plan_id == "" || reference_plan_id == undefined) {
    return
  }

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
    'benefit_group': {
      "reference_plan_id": reference_plan_id,
      "plan_option_kind": plan_option_kind,
    }
  }

  if(plan_option_kind == 'sole_source') {
    data['benefit_group']["composite_tier_contributions_attributes"] = relation_benefits;
  } else {
    data['benefit_group']["relationship_benefits_attributes"] = relation_benefits;
  }

    // runs on slider change
  $.ajax({
    type: "GET",
    url: url,
    dataType: 'script',
    data: data
  }).done(function() {
    // do something on completion?
  });

}

function initSlider() {
  $('.benefits-fields input.hidden-param, .dental-benefits-fields input.hidden-param').each(function() {
    $(this).closest('.form-group').find('.slider').attr('data-slider-value', $(this).val());
    $(this).closest('.form-group').find('.slide-label').html($(this).val()+"%");
  });

  $('.benefits-fields .slider').bootstrapSlider({
    formatter: function(value) {
      return 'Contribution Percentage: ' + value + '%';
    }
  });
}

function formatRadioButtons() {
  /*
  $('.fa-circle-o').each(function() {
    $(this).click(function() {
      $(this).toggleClass('fa-dot-circle-o fa-circle-o');
      console.log($(this).parent())
    });
  })
  */  
}
