console.log('hoo')
DT = ( function() {
  var clear_level = function(level) {
    level_str = String(level)
    $('.custom_level_' + level_str).addClass("hide")
    $('.custom_level_' + level_str+ ' .btn-default').removeClass("clicked")
  }
  var hide_lower_levels = function(button) {
    level = 0
    var button_group = $(button).parent()
    var button_group_class = button_group.attr('class')
    var get_level_regex = /custom_level_(\d)/
    var get_level = get_level_regex.exec(button_group_class)
    var level = parseInt(get_level && get_level[1])
    console.log(level)
    clear_level(level+1)
    clear_level(level+2)
    clear_level(level+3)
  }
  var filters= function(){
    $('.custom_level_1').removeClass('hide')
    $('.custom_filter .btn-default').click(function() {
      var that = this
      hide_lower_levels(that)
      if ($(that).hasClass('clicked')) {
        console.log('unclick')
        $(that).removeClass('clicked')
        return
      }
      $(this).addClass('clicked')
      id = $(this).attr('id').substring(4)
      $('.Filter-'+id).removeClass('hide')
    })
  }
  var filter_params = function(keys, level_str) {
    var selector = $('.custom_level_' + level_str + ' .clicked')
    if (typeof(selector) != 'undefined') {
      keys[selector.parent().attr('data-scope')] =  selector.attr('data-key')
    }
  }

  return {
  	filters: filters,
    filter_params: filter_params,
  }
})()