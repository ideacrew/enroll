# frozen_string_literal: true

Then(/^they should see the live chat button$/) do
  expect(page).to have_css(AdminHomepage.chat_button)
end

Then(/^they should see the bot button$/) do
  expect(page).to have_css(AdminHomepage.bot_button)
end

Then(/^they should not see the live chat button$/) do
  expect(page).to_not have_css(AdminHomepage.chat_button)
end

And(/^they click the live chat button$/) do
  find(AdminHomepage.chat_button).click
end

And(/^they see the live chat widget$/) do
  expect(page).to have_css(AdminHomepage.chat_widget_title)
end