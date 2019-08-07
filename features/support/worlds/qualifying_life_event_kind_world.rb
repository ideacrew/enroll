module QualifyingLifeEventKindWorld

  def qualifying_life_event_kind(qle_kind_title = nil)
    qle_kind = QualifyingLifeEventKind.where(title: qle_kind_title)
    if qle_kind.present?
      return qle_kind.first
    end
    @qle_kind ||= FactoryBot.create(
      :qualifying_life_event_kind,
      title: qle_kind_title.present? ? qle_kind_title : 'Married'
    )
  end

  def fill_qle_kind_form_and_submit(action_name, qle_kind_title)
    fill_in('qle_kind_creation_form_title', with: qle_kind_title)
    fill_in('qle_kind_creation_form_tool_tip', with: "Tool Tip")
    # select('', from: 'qle_kind_creation_form_action_kind')
    # select('', from: 'qle_kind_creation_form_reason')
    # Visible to Customer
    choose('qle_kind_edit_form_visible_to_customer', option: 'Yes')
    # Note: not using capybara 'choose' here because the 'option' param
    # is for value, but we're using ng-reflect-value
    inputs = page.all('input')
    shop_radio = inputs.detect { |input| input["ng-reflect-value"] == 'shop' }
    shop_radio.click
    # Self attested
    is_self_attested_radio = inputs.detect do |input|
      input[:id] == 'qle_kind_creation_form_is_self_attested' && input["ng-reflect-value"] == 'Yes'
    end
    is_self_attested_radio.click
    fill_in('qle_kind_creation_form_pre_event_sep_eligibility', with: '10')
    fill_in('qle_kind_creation_form_post_event_sep_eligibility', with: '10')
    fill_in('qle_kind_creation_start_on', with: '10/10/2020')
    fill_in('qle_kind_creation_end_on', with: '10/20/2030')
    case action_name
    when 'new'
      click_button('Create QLE Kind')
    when 'edit'
    when 'deactivate'
    end
  end
end

World(QualifyingLifeEventKindWorld)

Given(/^qualifying life event kind (.*?) present$/) do |qle_kind_title|
  qualifying_life_event_kind(qle_kind_title)
end

And(/^.+ clicks the Manage QLE link$/) do
  click_link 'Manage QLEs'
end

Then(/^.+ should see the QLE Kind Wizard$/) do
  expect(page.current_path).to eq(manage_exchanges_qles_path)
  expect(page).to have_content("Manage Qualifying Life Events")
end

And(/^.+user visits the new Qualifying Life Event Kind page$/) do
  visit(manage_exchanges_qles_path)
end

And(/^.+ visits the (.*?) Qualifying Life Event Kind page for (.*?) QLE Kind$/) do |which_action, qle_kind_title|
  qle_kind = qualifying_life_event_kind(qle_kind_title)
  case which_action
  when 'deactivate'
    visit(deactivate_form_exchanges_qle_path(qle_kind))
  when 'edit'
    visit(edit_exchanges_qle_path(qle_kind))
  end
end

# TODO: Need to implement reusable step for edit and deactivate
And(/^.+ selects (.*?) and clicks submit$/) do |which_action|
  case which_action
  when 'Create a Custom QLE'
    choose('qle_wizard_new_qle_selected_radio')
    click_button('Submit')
  when 'Modify Existing QLE, Market Kind, and first QLE Kind'
    choose('qle_wizard_modify_qle_selected_radio')
    choose('qle_wizard_kind_selected_radio_category_shop')
    first_qle_kind = QualifyingLifeEventKind.first
    first_qle_kind_option_value = deactivation_form_exchanges_qle_path(first_qle_kind._id)
    options = page.all('option')
    first_qle_kind_option = options.detect { |option| option[:value] == first_qle_kind_option_value }
    first_qle_kind_option.click
    click_button('Submit')
  when 'Deactivate Active QLE, Market Kind, and first QLE Kind'
    choose('qle_wizard_deactivate_qle_selected_radio')
    click_button('Submit')
  end
end

When(/^.+ fills out the (.*?) QLE Kind form for (.*?) event and clicks submit$/) do |action_name, qle_kind_title|
  fill_qle_kind_form_and_submit(action_name, qle_kind_title)
end
