jQuery ->
  $('form').on 'click', '.add_fields', (event) ->
    event.preventDefault()
    time = new Date().getTime()
    regexp = new RegExp($(this).data('id'), 'g')
    html = $(this).data('fields').replace(regexp, time)
    $(this).closest('.form-inputs').find('fieldset:last').after(html)

    style_select_picker()
    update_delete_buttons()

  $('form').on 'click', '.remove_fields', (event) ->
    event.preventDefault()
    $(this).closest('fieldset').remove()
    update_delete_buttons()

style_select_picker = ->
	$(document).find('select').select2()

@update_delete_buttons = ->
  nested_fields = $('.form-inputs')
  nested_fields.each ->
    visible_fieldsets = $(this).find('fieldset:visible')
    delete_button = visible_fieldsets.find('.remove_fields')
    if visible_fieldsets.length == 1
      delete_button.hide()
    else
      delete_button.show()