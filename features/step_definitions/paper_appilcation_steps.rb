When(/^the Admin selects the Paper application option$/) do
  find(:xpath, "//select[@name='person[family][application_type]']/option[@value='Paper']")
end