$(document).ready(function () {
  // Customize Dependent Family Member Delete Confirmation
  $('#family .remove').click(function() {
    var current_element = $(this).closest("#family .family_members_list");
    var confirm_buttons = 'single_row';
    override_confirmation( $(this), current_element, confirm_buttons, '#family .family_members_list' );    
  });

  $('#dependent_ul').on('click', '.close-2', function() {
      var current_element = $(this).closest(".dependent_list .house");
      var confirm_buttons = 'double_row';
      override_confirmation( $(this), current_element, confirm_buttons, 'div.house' );
  });

  // Overrides javascript default confirm modal
  function override_confirmation(thisObj, element, confirm_buttons, closest_element) {
    $.rails.allowAction = function(link) {
      if (!link.attr('data-confirm')) {
        return true;
      }
      $.rails.showConfirmDialog(link);
      return false;
    };

    $.rails.confirmed = function(link) {
      link.removeAttr('data-confirm');
      return link.trigger('click.rails');
    };

    return $.rails.showConfirmDialog = function(link) {
      var html;
      if(confirm_buttons == 'single_row') {
        html = '<div>' + link.data('confirm') + '<a href="javascript:;" class="btn remove_dependent cancel">' + (link.data('cancel')) + '</a> <a class="btn remove_dependent confirm" href="javascript:void(0);">' + (link.data('ok')) + '</a></div>';
      } else {
        html = '<div>' + link.data('confirm') + '</div><a href="javascript:void(0);" class="btn remove_dependent cancel">' + (link.data('cancel')) + '</a> <a class="btn remove_dependent confirm" href="javascript:void(0);">' + (link.data('ok')) + '</a>';
      }

      thisObj.closest(closest_element).find("#remove_confirm")
        .html(html)
        .removeClass('hidden');

      $('.remove_dependent').on('click', function() {
        $(this).closest("div.house").css('border-color', '#007bc3');
        $(this).closest("#remove_confirm")
          .addClass('hidden')
          .html('');
      });

      return $('#remove_confirm .confirm').on('click', function() {
        return $.rails.confirmed(link);
      });
    };
  }
});