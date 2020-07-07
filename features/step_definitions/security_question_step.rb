def question_attrs
  { title: 'Updated security question', visible: false }
end

Given 'There are preloaded security question on the system' do
  step "there are 3 preloaded security questions"
end

Given(/^the user click on config drop down in the Admin Tab$/) do
  find(:xpath, '//*[@id="myTab"]/li[13]/ul/li[4]/a/span[1]').click
end

Then(/^user should able to see Secuity Questions$/) do
  expect(page).to have_content("Security Questions")
end

Then(/^there is (\d+) questions available in the list$/) do |num|
  sleep 3
  expect(page.all('table.table-wrapper tbody tr').count).to eq(num.to_i)
end

When(/^Hbx Admin clicks on (.*?) Question link$/) do |link|
  link_title =  if link.eql?('Security')
                  'Security Question'
                elsif link.eql?('New')
                  'New Question'
                elsif link.eql?('Edit')
                  'Edit'
                elsif link.eql?('Delete')
                  'Delete'
                end
  click_link(link_title)
end

Given(/^user will clicks on New Question link$/) do
  find_link('New Question').click
end

Then(/^user fill out New Question form detail$/) do
  fill_in 'security_question_title', :with => 'First security question'
end

Then(/^Hbx Admin should see (.*?) Question form$/) do |text|
  expect(page).to have_content("#{text} Question")
end

Then(/^Hbx Admin fill out New Question form detail$/) do
  fill_in 'security_question_title', :with => 'First security question'
end

Then(/^Hbx Admin update the question title$/) do
  fill_in 'security_question_title', :with => question_attrs[:title]
end

When(/^Hbx Admin submit the question form$/) do
  page.find_button('submit').click
end

Then(/^there (is|are) (\d+) preloaded security questions$/) do |text, num|
  (0...num.to_i).each do |int|
    FactoryGirl.create(:security_question, title: "Security Question #{int.to_i + 1}")
  end
end

Then(/^user should see already in use text$/) do
  expect(page).to have_content("That Question is already in use")
end


Then(/^the question title updated successfully$/) do
  page.all('table.table-wrapper tbody tr').last.should(have_content(question_attrs[:title]))
end

Then 'I confirm the delete question popup' do
  page.evaluate_script('window.confirm = function() { return true; }')
end

Given(/^user click on Security Question link$/) do
  find_link('Security Question').click
end

When(/^Hbx Admin click on Edit Question link$/) do
  click_link("Edit", :match => :first)
end

When(/^Hbx Admin click on Delete Question link$/) do
  find(:xpath, "(//a[text()='Delete'])[2]").click
end

When /^Hbx Admin confirm popup$/ do
  page.driver.browser.switch_to.alert.accept
end

Then(/^I can(not)? see the security modal dialog$/) do |negate|
  if negate
    page.should(have_no_css('#securityQuestionModalLabel', visible: true, wait: 5))
  else
    page.should(have_css('#securityQuestionModalLabel', visible: true, wait: 5))
  end
end

# Old one, doesn't seem to be working for choosing the questions
Then(/^I select the all security question and give the answer$/) do
  (0..2).each do |num|
    within all('div.selectric-wrapper.selectric-security-question-select', visible: false)[num] do
      sleep 1
      find('.selectric').click
      sleep 1
      all('li')[-1].click
      sleep 1
    end

    # page.all('div.selectric-wrapper.selectric-security-question-select', visible: false)[num].find('.selectric-scroll').click
    # page.all('.security-question-select', visible: false)[num].set("Security Question #{num + 1}") #TODO verify why we are setting question here.
    page.all('.interaction-field-control-security-question-response-question-answer', visible: false)[num].set("Answer #{num+1}")
  end
end

When(/^user fills out the security questions modal$/) do
  security_questions = SecurityQuestion.all.to_a.map(&:id)
  (0..2).each do |num|
    within all('div.selectric-wrapper.selectric-security-question-select', visible: false)[num] do
      sleep 1
      find('.selectric').click
      sleep 1
      all('li')[-1].click
      sleep 1
    end
    page.all('.interaction-field-control-security-question-response-question-answer', visible: false)[num].set("Answer #{num+1}")
  end
end

When(/^.+ submits termination reason$/) do
  waiver_modal = find('#waive_confirm')
  waiver_modal.find(:xpath, "//div[contains(@class, 'selectric')][p[contains(text(), 'Please select waive reason')]]").click
  waiver_modal.find(:xpath, "//div[contains(@class, 'selectric-scroll')]/ul/li[contains(text(), 'I have coverage through Medicaid')]").click
  waiver_modal.find('#waiver_reason_submit').click
end

When(/I have submitted the security questions$/) do
  screenshot("group_selection")
  find('.interaction-click-control-save-responses').click
end

Then 'I have landed on employer profile page' do
  page.should(have_content("Thank you for logging into your #{Settings.site.short_name} employer account."))
end
