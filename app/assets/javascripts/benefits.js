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
    $(this).find('.make-default').hide();
  }
});
$('.benefit-package').mouseenter(function() {
  $(this).find('.make-default').show();
  $(this).find('.make-default').attr('data-toggle', 'tooltip');
  $(this).find('.make-default').attr('data-original-title', 'Make this your default benefit group');


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

};

$(document).ready(ready);
$(document).on('page:load', ready);
