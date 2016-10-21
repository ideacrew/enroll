DT = ( function() {
  var clear_level = function(level) {
    level_str = String(level)
    $('.custom_level_' + level_str).addClass("hide")
    $('.custom_level_' + level_str+ ' .btn-default').removeClass("active")
    if (level < 4) {
      clear_level(level + 1)
    }
  }
  var hide_lower_levels = function(button) {
    level = 0
    var button_group = $(button).parent()
    var button_group_class = button_group.attr('class')
    var get_level_regex = /custom_level_(\d)/
    var get_level = get_level_regex.exec(button_group_class)
    var level = parseInt(get_level && get_level[1])
    clear_level(level+1)
  }
  // intercept search keystrokes; inject them when there is a pause, check for backspace and enter
  var _wait_for_typing_to_finish = function(){
    window.dt_search_string = ''
    window.dt_search_delayed_draw_event = null
   $($('input.form-control.input-sm[type=search]')[0]).on('keydown', function(e) {
      if (e.keyCode == 8) {window.dt_search_string = window.dt_search_string.slice(0,-1)}
      else if (e.key.length == 1) { window.dt_search_string += e.key}
      clearTimeout(window.dt_search_delayed_draw_event)
      window.dt_search_delayed_draw_event = setTimeout(function(){
        $('input[type=search]').val(window.dt_search_string).trigger('keyup')},
        350)
      return false
    });
  }
  var clear_button_todojf = function() {          // Need to put this in the base framework
    setTimeout(
      function() {
        $($('.dataTables_filter label')[0]).append("<div class='btn btn-sm btn-default' style='display:inline'><span class='glyphicon glyphicon-remove'></span> </div>")
        $('.dataTables_filter .glyphicon-remove').on('click', function(){
          window.dt_search_string = ''
          $('input[type=search]').val(window.dt_search_string).trigger('keyup');
        })
       _wait_for_typing_to_finish()
      },
      50
    )
  }
  var filters = function(){
    $('.custom_level_1').removeClass('hide')
    $('.custom_filter .btn-default').click(function() {
      var that = this
      hide_lower_levels(that)
      if ($(that).hasClass('active')) {
        $(that).removeClass('active')
        return
      }
      $(that.parentElement.children).removeClass('active')
      $(that).addClass('active')
      id = $(that).attr('id').substring(4).replace(/\//g,'-')
      $('.Filter-'+id).removeClass('hide')
      $('.effective-datatable').DataTable().draw()
    })
    clear_button_todojf()
    extendDatatableServerParams = function(){
      var keys = {}
      DT.filter_params(keys, 1)
      var attributes_for_filtering = {"attributes": keys}
      return attributes_for_filtering;
    }
  }
  var filter_params = function(keys, level) {
    var selector = $('.custom_level_' + level + ' .active')
    if (typeof(selector) != 'undefined' && selector.size() > 0) {
      keys[selector.parent().attr('data-scope')] =  selector.attr('data-key')
      filter_params(keys, level+1)
    }
  }
  return {
  	filters: filters,
    filter_params: filter_params,
  }
})()
