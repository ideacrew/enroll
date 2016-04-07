var benefits_tab_js;
ready = function() {
  // open published years

  
  //toggling of divs that show plan details (view details)
  $('.nav-toggle').click(function(){
    //get collapse content selector
    var collapse_content_selector = $(this).attr('href');         
        
    //make the collapse content to be shown or hide
    var toggle_switch = $(this);
    $(collapse_content_selector).slideToggle('fast', function(){
      if($(this).css('display')=='none'){
        toggle_switch.html('View Details <i class="fa fa-chevron-down fa-lg">');
        //$(collapse_content_selector).animate({top: "0px"}, 500);
      }else{
        toggle_switch.html('Hide Details <i class="fa fa-chevron-up fa-lg">');
        //$(collapse_content_selector).animate({top: "0px"}, 500);
      }
    });
  });

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
    if ($(this).hasClass('active')) {} else {

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
        $(this).closest('.benefitgroup').find('.tooltip-inner').text('This is your default benefit group');
        $(this).attr('data-original-title', 'This is your default benefit group');
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
