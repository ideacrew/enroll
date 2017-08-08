def question_attrs
  { title: 'Updated security question', visible: false }
end

Then(/^Hbx Admin should see Security Question link$/) do
  find_link('Security Question').visible?
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

Then(/^Hbx Admin should see (.*?) Question form$/) do |text|
  expect(page).to have_content("#{text} Question")
end

Then(/^Hbx Admin fill out New Question form detail$/) do
  fill_in 'question_title', :with => 'First security question'
end

Then(/^Hbx Admin update the question title$/) do
  fill_in 'question_title', :with => question_attrs[:title]
end

When(/^Hbx Admin submit the question form$/) do
  page.find_button('submit').trigger('click')
end

Then(/^there (is|are) (\d+) preloaded security questions$/) do |text, num|
  (0...num.to_i).each do |int|
    FactoryGirl.create(:question, title: "Security Question #{int.to_i}")
  end
end

Then(/^the question title updated successfully$/) do
  page.all('table.table-wrapper tbody tr').last.should(have_content(question_attrs[:title]))
end

Then 'I confirm the delete question popup' do
  page.evaluate_script('window.confirm = function() { return true; }')
end