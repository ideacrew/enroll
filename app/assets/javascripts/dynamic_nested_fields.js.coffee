ready = ->
  $('form').on 'click', '.add_fields', (event) ->
    event.preventDefault()
    time = new Date().getTime()
    regexp = new RegExp($(this).data('id'), 'g')
    html = $(this).data('fields').replace(regexp, time)
    target = $(this).closest('.form-inputs')
    if $(target).children('fieldset:last').length > 0
      $(target).children('fieldset:last').after(html)
    else
      $(target).prepend(html)

    update_delete_buttons()

  $('form').on 'click', '.remove_fields', (event) ->
    $(this).closest('fieldset').remove()
    event.preventDefault()

@update_delete_buttons = ->
  nested_fields = $('.form-inputs')
  nested_fields.each ->
    visible_fieldsets = $(this).find('fieldset:visible')
    delete_button = visible_fieldsets.find('.remove_fields')
    if visible_fieldsets.length == 1
      delete_button.hide()
    else
      delete_button.show()

#$(document).ready(ready)
$(document).on('page:load', ready)
$(document).on('page:update', ready)
