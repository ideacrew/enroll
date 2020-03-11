Given(/^Employer exists and logs in$/) do
  login_as @staff_role
end

Then(/^Employee should click on Manage Family button$/) do
  find('a.interaction-click-control-manage-family').click
end

Then(/^Employee should click on the Personal Tab link$/) do
  find('a.interaction-click-control-personal').click
end

Then(/^Employee should click on Change my Password link$/) do
  if aca_security_questions
    wait_for_ajax
    page.execute_script("document.querySelector('#change_password_link').click()")
  end
end

Then(/they can submit a new password/) do
  fill_in 'user[password]', with: "aA1!aA1!aA1!"
  sleep 1
  fill_in 'user[new_password]', with: "NewPass!@$1234"
  sleep 1
  fill_in 'user[password_confirmation]', with: "NewPass!@$1234"
  sleep 1
  page.find_button('Change my password').click
end

Then(/^Employee will submit with wrong password$/) do
  fill_in 'user[password]', with: 'aA1!aA1!'
  fill_in 'user[new_password]', with: 'NewPass!@#$1234'
  fill_in 'user[password_confirmation]', with: 'NewPass!@#$1234'
  sleep 1
  page.find_button('Change my password').click
end

And(/^Employee (.*) replaces their spouse personal information with that of their child$/) do |named_person|
  person = people[named_person]
  person_record = Person.where(first_name: person[:first_name], last_name: person[:last_name]).first
  spouse = person_record.person_relationships.where(kind: "spouse").first.person
  links = page.all('a')
  edit_link_for_dependent = links.detect { |link| link.text == "Edit Dependent #{spouse.first_name} #{spouse.last_name}" }
  binding.pry
  edit_link_for_dependent.click
  fill_in('person[first_name]', with: spouse.first_name)
  fill_in('person[last_name]', with: spouse.last_name)
  choose('person_gender_female')
  binding.pry

end


Then(/^they should see a password does not match error$/) do
  expect(page).to have_text "That password does not match the one we have stored"
end

Then(/^I should see page redirected to Manage Family$/) do
  expect(page).to have_text "Manage Family"
end
