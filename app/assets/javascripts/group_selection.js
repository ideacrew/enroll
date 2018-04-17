$(document).ready(function() {
 setGroupSelectionHandlers();
});

function setGroupSelectionHandlers(){

  var employers = $("[id^=census_employee_]");
  hideAllErrors();

  toggleErrosOnEmployerSelection();

  if($('#market_kinds').length) {
    var employer_id = ""

    if ( $('#market_kind_individual').is(':checked') ) {
      $('#dental-radio-button').show();
      hideShopErrors();
      $('.ivl_errors').show();

      disableEmployerSelection();
      disableIvlIneligible();
      setPrimaryForIvl();
    }
    $('#market_kind_individual').on('change', function() {
      disableEmployerSelection();

      $('#dental-radio-button').slideDown();
      hideShopErrors();
      $('.ivl_errors').show();

      disableIvlIneligible();
      setPrimaryForIvl();

    });

    $('#market_kind_shop').on('change', function() {
      employers.each( function() {
        $(this).prop("disabled", false);
        if($(this).hasClass('selected_employer')) {
          employer_id = $(this).attr("value")
          $(this).prop("checked", true);
          $(this).removeClass('selected_employer');
          setDentalBenefits($(this).attr('dental_benefits'));
        }
      });

      $("#coverage_kind_health").prop("checked", true);
      hideAllErrors();
      disableShopHealthIneligible(employer_id)
      $(".health_errors_" + employer_id ).show();
      setPrimaryForShop();
    });
  }

  $(document).on("change", "[id^=census_employee_]", function(event){
    if($('#coverage_kind_health:checked').length > 0) {
      errorsForChangeInEmployer(this);
      event.stopPropagation();
    }
  })
}

function setPrimaryForIvl() {
  $("tr.is_primary td:first-child input").attr("onclick", "return true;");
  $("tr.is_primary td:first-child input").prop("readonly", false);
}

function setPrimaryForShop() {
  $("tr.is_primary td:first-child input").attr("onclick", "return false;");
  $("tr.is_primary td:first-child input").prop("readonly", true);
}

function hideAllErrors(){
  hideShopErrors();
  hideIvlErrors();
}

function toggleErrosOnEmployerSelection() {
  if ($("#employer-selection .n-radio-group .n-radio-row").length) {

    var checked_er = $("#employer-selection .n-radio-group .n-radio-row input[checked^= 'checked']:enabled");

    if (checked_er.length) {
      var employer_id = checked_er.val();
      if ($('#coverage_kind_health').is(':checked')) {
        $(".health_errors_" + employer_id ).show();
      }

      if ($('#coverage_kind_dental').is(':checked')) {
        $(".dental_errors_" + employer_id ).show();
      }

      setDentalBenefits(checked_er.attr('dental_benefits'));
      errorsForChangeInCoverageKind(employer_id);
      setPrimaryForShop();
    }

  } else {

    $('#dental-radio-button').show();
    $('.ivl_errors').show();
    disableIvlIneligible();
    setPrimaryForIvl();
  }
}

function hideShopErrors() {
  $("[class^=dental_errors_]").hide();
  $("[class^=health_errors_]").hide();
}

function hideIvlErrors() {
  $('#coverage-household tr td.ivl_errors').hide();
}

function errorsForChangeInEmployer(element) {
  if ($(element).closest('#employer-selection-group').length > 0) {
    var employer_id = $(element).attr("value")
    $("#coverage_kind_health").prop("checked", true);
    hideAllErrors();
    if ($(element).is(":checked")) {
      setDentalBenefits($(element).attr('dental_benefits'));
    }
    personId = $('#person_id').val();
    var dataParams = {};
    var searchParams = window.location.search.replace('?', '').split('&');
    searchParams.forEach(function(param) {
      if(param.split('=')[0] == 'change_plan')
        dataParams['change_plan'] = param.split('=')[1];
      if(param.split('=')[0] == 'person_id')
        dataParams['person_id'] = personId;
      if(param.split('=')[0] == 'employee_role_id')
        dataParams['employee_role_id'] = employer_id;
      if(param.split('=')[0] == 'market_kind')
        dataParams['market_kind'] = param.split('=')[1];
      if(param.split('=')[0] == 'shop_for_plans')
        dataParams['shop_for_plans'] = param.split('=')[1];
      if(param.split('=')[0] == 'qle_id')
        dataParams['qle_id'] = param.split('=')[1];
      if(param.split('=')[0] == 'sep_id')
        dataParams['sep_id'] = param.split('=')[1];
    })

    console.log(dataParams);

    errorsForChangeInCoverageKind(employer_id);
    $.ajax({
      url: '/insured/group_selections/new.js',
      type: 'GET',
      data: dataParams
    }).done(function () {
      hideAllErrors();
      toggleErrosOnEmployerSelection();
      $('input[type="submit"]').each(function() {
        var element_id = $.trim($(this).val());
        if(element_id) {
            $(this).addClass('interaction-click-control-' + element_id.toLowerCase().replace(/[_&]| /gi, '-'));
        }
      });
    })
  }
}

function errorsForChangeInCoverageKind(employer_id){
  $('#coverage_kind_health').on('change', function() {
    hideAllErrors();
    if ($("#employer-selection .n-radio-group .n-radio-row input[checked^= 'checked']:enabled").length) {
      
      $(".health_errors_" + employer_id ).show();
      disableShopHealthIneligible(employer_id);

    } else {

      $(".ivl_errors").show();
      disableIvlIneligible();

    }
  });

  $('#coverage_kind_dental').on('change', function() {
    hideAllErrors();
    if ($("#employer-selection .n-radio-group .n-radio-row input[checked^= 'checked']:enabled").length) {
      
      $(".dental_errors_" + employer_id ).show();
      disableShopDentalIneligible(employer_id);

    } else {
      
      $(".ivl_errors").show();
      disableIvlIneligible();
    }
  });
}

function disableIvlIneligible() {
  $('#coverage-household tr').filter("[class^=ineligible_]").not(".ineligible_ivl_row").find('input').prop({'checked': true, 'disabled': false});
  $('#coverage-household tr').filter(".ineligible_ivl_row").find('input').prop({'checked': false, 'disabled': true});
}

function disableShopDentalIneligible(employer_id) {
  $('#coverage-household tr').filter("[class^=ineligible_]").not(".ineligible_dental_row_" + employer_id).find('input').prop({'checked': true, 'disabled': false});
  $('#coverage-household tr').filter(".ineligible_dental_row_" + employer_id).find('input').prop({'checked': false, 'disabled': true});
}

function disableShopHealthIneligible(employer_id) {
  $('#coverage-household tr').filter("[class^=ineligible_]").not(".ineligible_health_row_" + employer_id).find('input').prop({'checked': true, 'disabled': false});
  $('#coverage-household tr').filter(".ineligible_health_row_" + employer_id).find('input').prop({'checked': false, 'disabled': true});
}


function disableEmployerSelection(){
  var employers = $("[id^=census_employee_]");
  employers.each( function() {
    if($(this).is(":checked")) {
      $(this).addClass('selected_employer');
    }
    $(this).prop("disabled", true);
    $(this).prop("checked", false);
  });
}

function setDentalBenefits(dental_benefits){
  if(dental_benefits == 'true'){
    $('#dental-radio-button').slideDown();
  } else {
    $('#dental-radio-button').slideUp();
  }
}

$(function(){
  if ( $("#find_sep_link").length ) {
    $("#find_sep_link").click(function() {
      $(this).closest('form').attr('action', '/insured/families/find_sep');
      $(this).closest('form').attr('method', 'get');
      $(this).closest('form').submit();
    });
  }
})
