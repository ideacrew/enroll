Given(/^employer ABC Widgets visits benefits page$/) do
	visit "/"
	find(:xpath, '//*[@id="welcome-nav-options"]/div/a[5]').click
	find(:xpath, '//*[@id="uic-employers-right-menu"]/li[3]/a').click
end

And(/^Employer doesn't have benefit applications$/) do
	expect(page).to have_content("#{Settings.site.late_rates_message}")
	expect(page).to have_no_content("Edit Plan Year")
end

When(/^Employer clicks on Add PlanYear button$/) do
	click_link 'Add Plan Year'
end

Then(/^Employer should see shell plan year page$/) do
	#expect(page).to have_content("SAVE")
	expect(page).to have_content("Add Benefit Package")
	# find(:xpath, '//*[@id="uic-wrapper"]/div[1]/div/div[2]/span').click
	# find(:xpath, '//*[@id="uic-wrapper"]/div[1]/div').click
	# expect(page).to have_content((TimeKeeper.date_of_record + 1.months).strftime("%m/%d/%Y"))
	# find('ul', :text => "#{(TimeKeeper.date_of_record + 1.month).strftime('%m/%d/%Y')}").click
	# wait_for_ajax(3, 2)
	find(".broker-registration", wait: 10).click
end