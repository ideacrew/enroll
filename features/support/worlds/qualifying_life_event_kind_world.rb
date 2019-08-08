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
    case action_name
    when 'new'
      form_name = "creation_form"
      button_text = 'Create QLE Kind'
    when 'edit'
      form_name = 'edit_form'
      button_text = 'Update QLE Kind'
    when 'deactivate'
      # TODO: Fill out buttons and text
      form_name = "deactivation_form"
      button_text = nil
    end
    if %w[creation_form edit_form].include?(form_name)
      fill_in("qle_kind_#{form_name}_title", with: qle_kind_title)
      fill_in("qle_kind_#{form_name}_tool_tip", with: "Tool Tip")
      # select('', from: "qle_kind_#{form_name}_action_kind")
      # select('', from: "qle_kind_#{form_name}__reason")
      # Visible to Customer
      choose("qle_kind_#{form_name}_visible_to_customer", option: 'Yes')
      # Note: not using capybara 'choose' here because the 'option' param
      # is for value, but we're using ng-reflect-value
      inputs = page.all('input')
      shop_radio = inputs.detect { |input| input["ng-reflect-value"] == 'shop' }
      shop_radio.click
      # Self attested
      is_self_attested_radio = inputs.detect do |input|
        input[:id] == "qle_kind_#{form_name}_is_self_attested" && input["ng-reflect-value"] == 'Yes'
      end
      is_self_attested_radio.click
      fill_in("qle_kind_#{form_name}_pre_event_sep_eligibility", with: '10')
      fill_in("qle_kind_#{form_name}_post_event_sep_eligibility", with: '10')
      fill_in("qle_kind_#{form_name}_start_on", with: '10/10/2030')
      fill_in("qle_kind_#{form_name}_end_on", with: '10/20/2040')
      click_button(button_text)
    elsif form_name == 'deactivate'
      # TODO: Fill out deactivate form
      # TODO: Click deactivation button
      fill_in("qle_kind_#{form_name}_end_on", with: '10/10/2030')
      binding.pry
    end
  end

  def qle_kind_wizard_selection(action_name)
    case action_name
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

And(/^.+ visits the (.*?) Qualifying Life Event Kind page for (.*?) QLE Kind$/) do |action_name, qle_kind_title|
  qle_kind = qualifying_life_event_kind(qle_kind_title)
  case action_name
  when 'deactivate'
    visit(deactivation_form_exchanges_qle_path(qle_kind))
  when 'edit'
    visit(edit_exchanges_qle_path(qle_kind))
  end
end

# TODO: Need to implement reusable step for edit and deactivate
And(/^.+ selects (.*?) and clicks submit$/) do |action_name|
  qle_kind_wizard_selection(action_name)
end

When(/^.+ fills out the (.*?) QLE Kind form for (.*?) event and clicks submit$/) do |action_name, qle_kind_title|
  fill_qle_kind_form_and_submit(action_name, qle_kind_title)
end
