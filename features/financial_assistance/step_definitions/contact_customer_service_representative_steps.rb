#frozen_string_literal: true

When(/the consumer clicks the Get Help Signing Up Button?/) do
  find('.interaction-click-control-get-help-signing-up').click
end

Then(/they should see the Contact Customer Support and Certified Applicant Counselor links?/) do
  page.should have_content('Help from a Customer Service Representative')
  page.should have_content('Help from a Certified Applicant Counselor')
end

Then(/they should not see the Contact Customer Support and Certified Applicant Counselor links?/) do
  page.should_not have_content('Help from a Customer Service Representative')
  page.should_not have_content('Help from a Certified Applicant Counselor')
end
