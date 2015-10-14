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

// make so only one star can be active
$('.make-default').on('click', function() {
  $('.make-default').removeClass('active');
});

// $('.benefit-package .make-default').mouseenter(function () {
//   //replace code for css hover color change and use js
// }

$('.benefit-package .make-default').toggleClick(function () {
    $(this).addClass('active');
    $(this).removeAttr('data-toggle');
    $(this).removeAttr('data-original-title');
    $(this).show();
  }, function () {
    $(this).removeClass('active');
  });


  // toggle details in benefits only
  $('.benefit-details').toggleClick(function () {
    $(this).closest('.benefit-package').next().find('.plan-details').show();
    $(this).html('Hide Details <i class="fa fa-chevron-up fa-lg"></i>');
  }, function () {
    $(this).closest('.benefit-package').next().find('.plan-details').hide();
    $(this).html('View Details <i class="fa fa-chevron-down fa-lg"></i>');


  });


};

$(document).ready(ready);
$(document).on('page:load', ready);
