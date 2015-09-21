
$(document).on('ready', function() {
  // nav tabs radios on change for plan selection




// set reference_plan_id
$(document).on('click', '.reference-plan input + label', function() {
  var reference_plan_id = $(this).closest('.reference-plan').find('input').attr('value');
  if (reference_plan_id != "" && reference_plan_id != undefined){
    var start_date = $("#plan_year_start_on").val();
    if (start_date == "") {
      return
    }
    $.ajax({
      type: "GET",
      url: $('a#search_reference_plan_link').data('href'),
      dataType: 'script',
      data: {
        "start_on": $("#plan_year_start_on").val(),
        "reference_plan_id": reference_plan_id,
        "location_id": $(this).parents('fieldset').attr('id')
      }
    }).done(function() {
      calcEmployerContributions($('a#calc_employer_contributions_link').data('href'));
    });
  };
});

  $(function() {

    $('.contribution_handler').each(function() {
      $(this).change(function(){
        calcEmployerContributions($('a#calc_employer_contributions_link').data('href'));
      });
    });

    $("#employer_cost_info_btn .btn").click(function(){
      var reference_plan_id = $("#plan_year_benefit_groups_attributes_0_reference_plan_id").val();
      if (reference_plan_id == "" || reference_plan_id == undefined) {
        return
      }
      calcEmployerContributions($('a#employee_costs_link').attr('href'));
    })
  });

  function calcEmployerContributions(url) {
    var reference_plan_id = $('.reference-plan input[type=radio]:checked').val();
    console.log(reference_plan_id);
    var plan_option_kind = $(".nav-tabs input[type=radio]:checked").val();
    console.log(plan_option_kind);

    if (reference_plan_id == "" || reference_plan_id == undefined) {
      return
    }

    var start_date = $("#plan_year_start_on").val();
    if (start_date == "") {
      return
    }

    var relation_benefits = {
      "0": {
        "relationship": "employee",
        "premium_pct": $('#plan_year_benefit_groups_attributes_0_relationship_benefits_attributes_0_premium_pct').val(),
        "offered": $('#plan_year_benefit_groups_attributes_0_relationship_benefits_attributes_0_offered').is(":checked")
      },
      "1": {
        "relationship": "spouse",
        "premium_pct": $('#plan_year_benefit_groups_attributes_0_relationship_benefits_attributes_1_premium_pct').val(),
        "offered": $('#plan_year_benefit_groups_attributes_0_relationship_benefits_attributes_1_offered').is(":checked")
      },
      "2": {
        "relationship": "domestic_partner",
        "premium_pct": $('#plan_year_benefit_groups_attributes_0_relationship_benefits_attributes_2_premium_pct').val(),
        "offered": $('#plan_year_benefit_groups_attributes_0_relationship_benefits_attributes_2_offered').is(":checked")
      },
      "3": {
        "relationship": "child_under_26",
        "premium_pct": $('#plan_year_benefit_groups_attributes_0_relationship_benefits_attributes_3_premium_pct').val(),
        "offered": $('#plan_year_benefit_groups_attributes_0_relationship_benefits_attributes_3_offered').is(":checked")
      },
      "4": {
        "relationship": "child_26_and_over",
        "premium_pct": $('#plan_year_benefit_groups_attributes_0_relationship_benefits_attributes_4_premium_pct').val(),
        "offered": $('#plan_year_benefit_groups_attributes_0_relationship_benefits_attributes_4_offered').is(":checked")
      }
    }
    $.ajax({
      type: "GET",
      url: url,
      dataType: 'script',
      data: {
        "start_on": $("#plan_year_start_on").val(),
        "reference_plan_id": reference_plan_id,
        "plan_option_kind": plan_option_kind,
        "relation_benefits": relation_benefits
      }
    }).done(function() {
    });;
  }

  $(document).on("click", ".reference_plan_info h4 span", function() {
    $(this).parents(".reference_plan_info").find('.content').toggle();
  });
});
