var benefits_tab_js;
ready = function() {

  // mimic jquery toggle function
  $.fn.toggleClick = function() {
    var functions = arguments,
      iteration = 0
    return this.click(function() {
      functions[iteration].apply(this, arguments)
      iteration = (iteration + 1) % functions.length
    })
  }

  $('.benefit-package').mouseleave(function() {
    if ($(this).find('.make-default').hasClass('active')) {} else {
      // $(this).find('.make-default').hide();
    }
  });

  $('.benefit-package').mouseenter(function() {
    $(this).find('.make-default').show();
    $(this).find('.make-default').attr('data-toggle', 'tooltip');
    if ($(this).find('.make-default').hasClass('active')) {
      $(this).find('.make-default').attr('data-original-title', 'This is your default benefit group');
    } else {
      $(this).find('.make-default').attr('data-original-title', 'Make this your default benefit group');
    }
  });

  // call makeDefaultBenefitGroup from click

  $('.benefit-package .make-default').on('click', function() {
    if ($(this).hasClass('active')) {
      alert('this is already your default benefit group');
    } else {

      $.ajax({
        context: this,
        type: "POST",
        url: $(this).closest('.benefit-package').find('a.make_default_benefit_group_link').data('href'),
        dataType: 'script',
        data: {
          "benefit_group_id": $(this).closest('.benefit-package').find('a.make_default_benefit_group_link').data('benefit-group-id'),
          "plan_year_id": $(this).closest('.benefit-package').find('a.make_default_benefit_group_link').data('plan-year-id')
        }
      }).done(function() {
        $('.make-default').removeClass('active');
        $(this).addClass('active');
      });

    }
  });

  // toggle details in benefits only
  $('.benefit-details').toggleClick(function() {
    $(this).closest('.benefit-package').next().find('.plan-details').show();
    $(this).html('Hide Details <i class="fa fa-chevron-up fa-lg"></i>');
  }, function() {
    $(this).closest('.benefit-package').next().find('.plan-details').hide();
    $(this).html('View Details <i class="fa fa-chevron-down fa-lg"></i>');
  });

};

$(document).ready(ready);
$(document).on('page:load', benefits_tab_js);
