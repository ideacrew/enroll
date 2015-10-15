var ready;
ready = function() {

// mimic jquery toggle function
$.fn.toggleClick=function(){
  var functions=arguments, iteration=0
  return this.click(function(){
    functions[iteration].apply(this,arguments)
    iteration= (iteration+1) %functions.length
  })
}

$('.benefit-package').mouseleave(function() {
  if ( $(this).find('.make-default').hasClass('active') ) {
  } else {
    // $(this).find('.make-default').hide();
  }
});

$('.benefit-package').mouseenter(function() {
  $(this).find('.make-default').show();
  $(this).find('.make-default').attr('data-toggle', 'tooltip');
  if ( $(this).find('.make-default').hasClass('active') ) {
    $(this).find('.make-default').attr('data-original-title', 'This is your default benefit group');
  } else {
    $(this).find('.make-default').attr('data-original-title', 'Make this your default benefit group');
  }
});

// TOGGLE CLICK FUNCTION FOR MAKING A BENEFIT GROUP DEFAULT
$('.benefit-package .make-default').toggleClick(function () {
    $(this).addClass('active');
    $(this).removeAttr('data-toggle');
    $(this).removeAttr('data-original-title');
    $(this).show();
  }, function () {
    $(this).removeClass('active');
  });

// call makeDefaultBenefitGroup from click

$('.benefit-package .make-default').on('click', function() {
  if ( $(this).find('.make-default').hasClass('active') ) {
  makeDefaultBenefitGroup();
  } else {
    $.ajax({
      type: "POST",
      url: $('a#search_reference_plan_link').data('href'),
      dataType: 'script',
      data: {
        "start_on": $("#plan_year_start_on").val(),
        "reference_plan_id": reference_plan_id,
        "location_id": location_id
      }
    }).done(function() {
      calcEmployerContributions($('a#calc_employer_contributions_link').data('href'), location_id);
    });

  }
});


  // toggle details in benefits only
  $('.benefit-details').toggleClick(function () {
    $(this).closest('.benefit-package').next().find('.plan-details').show();
    $(this).html('Hide Details <i class="fa fa-chevron-up fa-lg"></i>');
  }, function () {
    $(this).closest('.benefit-package').next().find('.plan-details').hide();
    $(this).html('View Details <i class="fa fa-chevron-down fa-lg"></i>');
  });

  function makeDefaultBenefitGroup() {
    alert(123);
  }

};

$(document).ready(ready);
$(document).on('page:load', ready);
