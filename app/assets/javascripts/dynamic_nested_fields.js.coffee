$(document).on 'click', 'form .add_fields', (event) ->
  event.preventDefault()
  time = new Date().getTime()
  regexp = new RegExp($(this).data('id'), 'g')
  html = $(this).data('fields').replace(regexp, time)
  target = $(this).closest('.form-inputs')
  if $(target).children('fieldset:last').length > 0
    $(target).children('fieldset:last').after(html)
  else
    $(target).prepend(html)
  $(target).children('fieldset:last').find('select').selectric()
  $(target).children('fieldset:last').find("input.floatlabel").floatlabel slideInput: false

  update_delete_buttons()
  applyJQDatePickers()

  if $('#plan_year_start_on').length
    validatePlanYear()


  $('.benefit-group-fields:last').attr 'id', 'benefit-group-' + time

  if window.location.href.indexOf('edit') > -1 and window.location.href.indexOf('plan_years') > -1
    $('.benefit-group-fields:last .edit-offering, .benefit-group-fields:last .reference-steps .cancel-plan-change').remove()
    $('.benefit-group-fields:last .reference-steps h1').html '<h1>Select Your Plan Offering</h1>'
    $('.benefit-group-fields:last .reference-steps .currently-offering').html 'Let your plan participants choose any plan they want offered by a single carrier, from a given metal level, or offer just a single plan.'
  else


  $('.benefit-group-fields:last').find('.benefits-fields .slider').bootstrapSlider
    formatter: (value) ->
      return 'Contribution Percentage: ' + value + '%'
  $('.benefit-group-fields:last').find('.benefits-fields .slider').on 'slide', (slideEvt) ->
    $(this).closest('.form-group').find('.hidden-param').val(slideEvt.value).attr 'value', slideEvt.value
    $(this).closest('.form-group').find('.slide-label').text slideEvt.value + '%'
    return
  $('.benefit-group-fields:last input[value="child_under_26"]').closest('.row-form-wrapper').attr('style','border-bottom: 0px;')
  $('.benefit-group-fields:last input:first').focus()
  $('.remove_fields:last').css('display', 'inline-block')

  $('.benefit-group-fields:last .contribution_slide_handler').each ->
    $(this).on 'slideStop', (slideEvt) ->
      location_id = $(this).parents('.benefit-group-fields').attr('id')
      calcEmployerContributions $('a#calc_employer_contributions_link').data('href'), location_id
      return
    return

  start_on = $('#plan_year_start_on').val()
  if start_on
    start_on = start_on.substr(0, 4)

    $('.plan-options a').each ->
      url = $(this).attr('href')
      $(this).attr 'href', url + '&start_on=' + start_on
  return

$(document).on 'click', 'form .remove_fields', (event) ->
  $(this).closest('fieldset').remove()
  event.preventDefault()

$(document).on 'click', '.benefits-setup-tab .remove_fields', (event) ->
  $('.benefit-group-fields:last').remove()
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
