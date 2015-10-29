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

calcEmployerContributions = (url, location) ->
  reference_plan_id = $('#' + location + ' .reference-plan input[type=radio]:checked').val()
  plan_option_kind = $('#' + location + ' .nav-tabs input[type=radio]:checked').val()
  location_id = location
  console.log reference_plan_id
  console.log location_id
  if reference_plan_id == '' or reference_plan_id == undefined
    return
  start_date = $('#plan_year_start_on').val()
  if start_date == ''
    return
  premium_pcts = $('#' + location + ' .benefits-fields input.hidden-param').map(->
    $(this).val()
  ).get()
  is_offered = $('#' + location + ' .benefits-fields .checkbox label > input[type=checkbox]').map(->
    $(this).is ':checked'
  ).get()
  relation_benefits = 
    '0':
      'relationship': 'employee'
      'premium_pct': premium_pcts[0]
      'offered': is_offered[0]
    '1':
      'relationship': 'spouse'
      'premium_pct': premium_pcts[1]
      'offered': is_offered[1]
    '2':
      'relationship': 'domestic_partner'
      'premium_pct': premium_pcts[2]
      'offered': is_offered[2]
    '3':
      'relationship': 'child_under_26'
      'premium_pct': premium_pcts[3]
      'offered': is_offered[3]
    '4':
      'relationship': 'child_26_and_over'
      'premium_pct': 0
      'offered': false
  $.ajax(
    type: 'GET'
    url: url
    dataType: 'script'
    data:
      'start_on': $('#plan_year_start_on').val()
      'reference_plan_id': reference_plan_id
      'plan_option_kind': plan_option_kind
      'relation_benefits': relation_benefits
      'location_id': location_id).done ->
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
