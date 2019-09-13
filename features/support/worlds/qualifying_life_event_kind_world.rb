
module QualifyingLifeEventKindWorld

  def qualifying_life_event_kind(qle_kind_title = nil, market_kind = 'shop')
    qle_kind = QualifyingLifeEventKind.where(title: qle_kind_title)
    if qle_kind.present?
      return qle_kind.first
    end
    @qle_kind ||= FactoryBot.create(
      :qualifying_life_event_kind,
      title: qle_kind_title.present? ? qle_kind_title : 'Married',
      market_kind: market_kind,
      visible_to_customer: true,
      event_kind_label: qle_kind_title.present? ? qle_kind_title + " took place on" : "Qualifying Life Event took place on"
    )
    question = @qle_kind.custom_qle_questions.create!(content: "test")
    question.custom_qle_responses.create!(content:"response", action_to_take: "accepted")
    @qle_kind
  end

  def create_custom_qle_kind_questions_and_responses(qle_kind_title = nil, action_to_take_1 = 'accepted')
    qle_kind = QualifyingLifeEventKind.where(title: qle_kind_title).first
    custom_qle_question = qle_kind.custom_qle_questions.build(
      content: "What is the name of your dog?"
    )
    custom_qle_question.save!
    custom_qle_question = qle_kind.custom_qle_questions.last
    custom_qle_question_response_1 = custom_qle_question.custom_qle_responses.build(
      content: "Fido",
      action_to_take: action_to_take_1
    )
    # TODO: Add action_to_take_2 arguement as 'declined'
    custom_qle_question_response_1.save!
    # custom_qle_question_response_2 = custom_qle_question.custom_qle_responses.build(
    #   content: "Jimmy",
    #   action_to_take: action_to_take_2
    # )
    # custom_qle_question_response_2.save!
  end

  def create_second_custom_qle_kind_question_and_responses(qle_kind_title = nil, which_action_to_take = 'accepted')
    qle_kind = QualifyingLifeEventKind.where(title: qle_kind_title).first
    expect(qle_kind.custom_qle_questions.count).to eq(1)
    second_custom_qle_question = qle_kind.custom_qle_questions.build(
      content: "Please, we need clarification, what is the name of your dog?"
    )
    second_custom_qle_question.save!
    second_custom_qle_question = qle_kind.custom_qle_questions.last
    second_qle_question_response_1 = second_custom_qle_question.custom_qle_responses.build(
      content: "Johnny",
      action_to_take: which_action_to_take
    )
    second_qle_question_response_1.save!
  end

  def fill_responses_to_qle_kind_responses_form(which_action_to_take = 'accepted', qle_kind_title)
    qle_kind = qualifying_life_event_kind(qle_kind_title)
    custom_qle_questions = qle_kind.custom_qle_questions
    # TODO: Make this an arguement'
    # TODO: Currently only creating a single response
    fill_in('question_and_responses[qle_date]', with: Date.today.to_s)
    # which_response_to_choose = qle_kind.custom_qle_questions.where(
    #  'custom_qle_responses.action_to_take' => which_action_to_take
    # ).first.custom_qle_responses.where(action_to_take: which_action_to_take).first ||
    # which_response_to_choose = qle_kind.custom_qle_questions.where(
    #   'custom_qle_response.action_to_take' => which_action_to_take
    # ).first.custom_qle_responses.where(action_to_take: which_action_to_take).first 
    # response_value_content = which_response_to_choose.content
    # all_lis = page.all('li')
    # which_response_to_choose_option = all_lis.detect { |li| li.text == response_value_content }
    # which_response_to_choose_option.click if which_response_to_choose_option.present?
    # Note: Selectric is weird, so we click by xpath first
    # esponse_options = find(:xpath, "//div[contains(@class, 'selectric-response-content-options')]")
    # response_options.click if which_response_to_choose_option.present?
    click_button 'Submit'
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
      # TODO: Selectric selects are considered not visible
      # However, they are set to `not_applicable` by default, which is valid.
      # remove selectric or find a work around to select them.
      # options = page.all('option')
      # Action kind
      # administrative_action_kind = options.detect { |option| option['ng-reflect-ng-value'] == 'administrative' }
      # administrative_action_kind.click
      # Reason
      # natural_disaster_option = options.detect { |option| option['ng-reflect-ng-value'] == 'exceptional_circumstances_natural_disaster' }
      # natural_disaster_option.click

      # TODO: Add these to the edit form too
      if form_name == 'creation_form'
        click_button('Create a New Question')
        # Question 1
        fill_in('qle_kind_question_0_title', with: "Did you just move to DC?")
        click_button('Add Response')
        fill_in('qle_kind_response_response_0_content', with: 'No')
        select('Declined', from: 'qle_kind_response_response_0_action_to_take')
        click_button('Create a New Question')
        sleep(2)
        buttons = page.all('button')
        add_response_buttons = []
        second_add_response = buttons.each { |button| add_response_buttons << button if button.text == 'Add Response' }
        add_response_buttons.second.click
        # TODO: These need to have the index properly added to them so they have different
        # IDS
        # fill_in('qle_kind_response_response_1_content', with: 'Yes')
        # select('Accepted', from: 'qle_kind_response_response_1_action_to_take')
      end
      # TODO: Consider modifying this step to allow visibility as false
      # Visible to Customer
      choose("qle_kind_#{form_name}_visible_to_customer", option: 'Yes')
      # Note: not using capybara 'choose' here because the 'option' param
      # is for value, but we're using ng-reflect-value
      inputs = page.all('input')
      # TODO: Consider modifying this step to allow different market kinds
      market_kind = 'individual'
      shop_radio = inputs.detect { |input| input["ng-reflect-value"] == market_kind }
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
      first_qle_kind_option_value = edit_exchanges_qle_path(first_qle_kind._id)
      options = page.all('option')
      first_qle_kind_option = options.detect { |option| option[:value] == first_qle_kind_option_value }
      first_qle_kind_option.click
      click_button('Submit')
    when 'Deactivate Active QLE, Market Kind, and first QLE Kind'
      choose('qle_wizard_deactivate_qle_selected_radio')
      first_qle_kind = QualifyingLifeEventKind.first
      first_qle_kind_option_value = deactivation_form_exchanges_qle_path(first_qle_kind._id)
      first_qle_kind_option_value = edit_exchanges_qle_path(first_qle_kind._id)
      options = page.all('option')
      first_qle_kind_option = options.detect { |option| option[:value] == first_qle_kind_option_value }
      first_qle_kind_option.click
      click_button('Submit')
    end
  end
end

World(QualifyingLifeEventKindWorld)

Given(/^qualifying life event kind (.*?) present for (.*?) market$/) do |qle_kind_title, market_kind|
  qualifying_life_event_kind(qle_kind_title, market_kind)
end

And(/^qualifying life event kind (.*?) is not active$/) do |qle_kind_title|
  qle_kind = qualifying_life_event_kind(qle_kind_title)
  qle_kind.is_active = false
  qle_kind.save!
end

And(/^qualifying life event kind (.*?) has custom qle question and accepted response present$/) do |qle_kind_title|
  create_custom_qle_kind_questions_and_responses(qle_kind_title)
end


And(/^qualifying life event kind (.*?) has custom qle question and declined response present$/) do |qle_kind_title|
  create_custom_qle_kind_questions_and_responses(qle_kind_title, 'declined')
end

And(/^qualifying life event kind (.*?) has two custom qle questions with a to_question_2 response present$/) do |qle_kind_title|
  create_custom_qle_kind_questions_and_responses(qle_kind_title, 'to_question_2')
  create_second_custom_qle_kind_question_and_responses(qle_kind_title, 'accepted')
end

And(/^qualifying life event kind (.*?) has custom qle questions with call_center response present$/) do |qle_kind_title|
  create_custom_qle_kind_questions_and_responses(qle_kind_title, 'call_center')
end

And(/^all qualifying life event kinds (.*?) to customer$/) do |visible_to_customer|
  case visible_to_customer
  when 'are visible'
    QualifyingLifeEventKind.update_all(visible_to_customer: true)
  when 'are not visible'
    QualifyingLifeEventKind.update_all(visible_to_customer: false)
  end
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

Then("user should see an edit form with the existing QLEKind information loaded") do
  expect(current_path).to eq(edit_exchanges_qle_path(@qle_kind))
  save_and_open_page
end
# TODO: Need to implement reusable step for edit and deactivate
And(/^.+ selects (.*?) and clicks submit$/) do |action_name|
  qle_kind_wizard_selection(action_name)
end

When(/^.+ fills out the (.*?) QLE Kind form for (.*?) event and clicks submit$/) do |action_name, qle_kind_title|
  fill_qle_kind_form_and_submit(action_name, qle_kind_title)
end

Then(/^user should see message QLE Kind (.*?) has been sucessfully (.*?)$/) do |qle_kind_title, action_name|
  expect(page).to have_content("Successfully #{action_name} Qualifying Life Event Kind.")
  qle_kind = qualifying_life_event_kind(qle_kind_title)
  if %w[created updated].include?(action_name)
    first_custom_qle_question = qle_kind.custom_qle_questions.first
    expect(first_custom_qle_question.present?).to eq(true)
    first_response = first_custom_qle_question.custom_qle_responses.first
    expect(first_response.present?).to eq(true)
  end
  # TODO: Use this for the deactivate cucumber
  if action_name == 'deactivated'
    expect(qle_kind.end_on.present?).to eq(true)
  end
end

And(/I see the first custom qle question for (.*?) qualifying life event kind$/) do |qle_kind_title|
  qle_kind = qualifying_life_event_kind(qle_kind_title)
  first_custom_qle_question = qle_kind.custom_qle_questions.first
  first_qle_kind_custom_qle_question_content = first_custom_qle_question.content
  expect(page).to have_content(first_qle_kind_custom_qle_question_content)
end

And(/I see the second custom custom qle question for (.*?) qualifying life event kind$/) do |qle_kind_title|
  qle_kind = qualifying_life_event_kind(qle_kind_title)
  second_custom_qle_question = qle_kind.custom_qle_questions.last
  second_qle_kind_custom_qle_question_content = second_custom_qle_question.content
  expect(page).to have_content(second_qle_kind_custom_qle_question_content)
end


# TODO: Make sure the proper question appears here
And(/I see the custom qle questions for (.*?) qualifying life event kind$/) do |qle_kind_title|
  qle_kind = qualifying_life_event_kind(qle_kind_title)
  expect(page.current_path). to eq(custom_qle_question_insured_family_path(qle_kind.id))
end

And(/I fill out the (.*?) response for (.*?) qualifying life event kind$/) do |which_action_to_take, qle_kind_title|
  fill_responses_to_qle_kind_responses_form(which_action_to_take, qle_kind_title)
end

And(/I see the new insured group selection page and a message confirming that I can enroll$/) do
  expect(page).to have_content("You are eligible to enroll. Please continue.")
  expect(page.current_path).to eq(insured_family_members_path)
end

And(/I see the call center page and a phone number to call so I can be approved for enrollment$/) do
  expect(page).to have_content(
    "Based on the information you entered, you may be eligible for a special enrollment period." \
    " Please call us at #{Settings.contact_center.phone_number} to give us more information so we can see if you qualify."
  )
end

And(/I see the home page and a message informing me that I'm unable to enroll$/) do
  expect(page.current_path).to eq(home_insured_families_path)
end
