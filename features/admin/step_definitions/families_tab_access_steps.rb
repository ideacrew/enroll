When(/^Hbx Admin navigate to main page$/) do
	visit exchanges_hbx_profiles_root_path
end

When(/^admin should see families dropdown link in main tabs$/) do
	expect(page).to have_xpath("/html/body/div[2]/div/ul/li[2]/a", text: 'Families')
end

When(/^ciclks on families dropdown link in main tabs$/) do
	click_link "Families"
end

Then(/^admin  should see all links in families dropdown$/) do
	find(:xpath, "/html/body/div[2]/div/ul/li[2]/ul/li[1]/a/span[1]", text: 'Families')[:class].include?("blocking") == false
	find(:xpath, "/html/body/div[2]/div/ul/li[2]/ul/li[2]/a/span[1]", text: 'Outstanding Verifications')[:class].include?("blocking") == false
	find(:xpath, "/html/body/div[2]/div/ul/li[2]/ul/li[3]/a/span[1]", text: 'New Consumer Application')[:class].include?("blocking") == false
	find(:xpath, "/html/body/div[2]/div/ul/li[2]/ul/li[4]/a/span[1]", text: 'Identity Verification')[:class].include?("blocking") == false
end

Then(/^admin should see only outstanding verifications link in families dropdown$/) do
  find(:xpath, "/html/body/div[2]/div/ul/li[2]/ul/li[2]/a/span[1]", text: 'Outstanding Verifications')[:class].include?("blocking") == false
end

Then(/^admin should see only new consumer application link in families dropdown$/) do
  find(:xpath, "/html/body/div[2]/div/ul/li[2]/ul/li[3]/a/span[1]", text: 'New Consumer Application')[:class].include?("blocking") == false
end