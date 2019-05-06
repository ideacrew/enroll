When(/^the Admin selects the In Person application option$/) do
	find(:xpath, "//select[@name='person[family][application_type]']/option[@value='In Person']")
end

When(/^the Admin clicks CONTINUE after uploading and verifying an Identity$/) do
	find('#upload_identity').click
  find('#select_upload_identity').click
  within '#select_upload_identity' do
    attach_file("file[]", "#{Rails.root}/lib/pdf_templates/blank.pdf", visible:false)
  end
  wait_for_ajax(10,2)
  find(:xpath,"//*[@id='Identity']/div/div[4]/div").click
  find('.interaction-choice-control-verification-reason-1').click
  find('.selectric-interaction-choice-control-verification-reason').click
  find("li", :text => "Document in EnrollApp").click
  find('.v-type-confirm-button').click
  expect(page).to have_content('Identity successfully verified.')
  find('.button', text: 'Continue').click
end
