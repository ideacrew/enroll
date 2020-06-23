Then(/^the user will( not)? see the Send Secure Message button$/) do |visible|
  if visible.blank?
    expect(page).to have_css('.btn.btn-xs', text: 'Send Secure Message')
  else
    expect(page).to_not have_css('.btn.btn-xs', text: 'Send Secure Message')
  end
end

When(/^the user clicks the Send Secure Message button for this Employer$/) do
  find('.btn.btn-xs', text: 'Send Secure Message').click
end

Then("the Secure message form should have Subject and Content as required fields") do
  find_field('subject')[:required].should be_present
  find_field('body')[:required].should be_present
end

Then(/^the user will see the Send Secure Message option form$/) do
  expect(page).to have_css('input[type="file"]')
  expect(page).to have_text('RECIPIENT')
  expect(page).to have_text('SUBJECT')
  expect(page).to have_text('CONTENT')
  expect(page).to have_text('DOCUMENT')
  expect(page).to have_css("textarea[placeholder='Write here...']")
  expect(page).to have_button('Send', disabled: false)
  expect(page).to have_button('Cancel', disabled: false)
end

Then(/^the user will not see the Send Secure Message option form$/) do
  expect(page).not_to have_css('input[type="file"]')
  expect(page).not_to have_text('RECIPIENT')
  expect(page).not_to have_text('SUBJECT')
  expect(page).not_to have_text('CONTENT')
  expect(page).not_to have_text('DOCUMENT')
  expect(page).not_to have_css("textarea[placeholder='Write here...']")
  expect(page).not_to have_button('Send', disabled: false)
  expect(page).not_to have_button('Cancel', disabled: false)
end

When("the user clicks cancel button") do
  find("#secureMessageFormClose").click
end

Then(/^the Recipient field should auto populate with the Employer groups name (.*?)$/) do|legal_name|
  expect(page).to have_text(legal_name)
end