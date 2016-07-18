var Enroll = (function(window, undefined) {

  function cacheDom() {
    dom = $('html').html();
    return dom;
  }

  function preventUnload() {
    $(window).load(function() {
      $values_on_load = [];
      $('form input').each(function(index, value) {
        $values_on_load.push($(this).val());
      });
      $(document).bind("click", "a", compareFormValues(event.target));
    });
  }

  compareFormValues = function($thisObj) {
    $values_on_exit = [];
    $('form input').each(function(index, value) {
      $values_on_exit.push($(this).val());
    });
    if ( $thisObj.hasClass('form-can-submit') == true ) {
    } else if ($values_on_exit.toString() == $values_on_load.toString()) {
      event.preventDefault();
      $thisObj.addClass('form-can-submit');
      $('.form-can-submit').trigger('click');
    } else {
      alert("You need to save first");
      event.preventDefault();
      return;
    }
  }

  return {
    cacheDom: cacheDom,
    preventUnload: preventUnload
  };

})(window);
