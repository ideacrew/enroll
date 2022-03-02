# frozen_string_literal: true

module UIHelpers
  module WorkflowHelper
    def find_previous_from_step_one
      model_name = @model.class.to_s.split('::').last.downcase
      if  model_name == "applicant"
        financial_assistance.edit_application_path(@application)
      elsif model_name == "application"
        financial_assistance.review_and_submit_application_path(@application)
      else
        send("financial_assistance.application_applicant_#{model_name.pluralize}_path", @application, @applicant)
      end
    end

    def workflow_form_for(model)
      path, method = if model.new_record?
                       [controller.request.path.sub('new', 'step'), :post]
                     else
                       [controller.request.path.sub('new', "#{model.id}/step"), :put]
                     end
      path.gsub!(%r{step/\d$}, 'step')
      form_tag path, method: method do
        yield
      end
    end

    def previous_step_for
      controller.request.path.gsub(%r{step(?:/\d)?$}, "step/#{@current_step.to_i - 1}")
    end

    # The following helper methods are for populating the persisted values of each
    # attributes from the model during the construction of the HTML element.

    # Radio Button
    def radio_checked?(model, cell)
      cell.value == model.send(cell.attribute) if cell.attribute.present?
    end

    # Dropdown
    def selected_value(model, cell)
      if cell.accessor.nil?
        model.send(cell.attribute)
      else
        access_path = cell.accessor.join('.')
        related_model = model.instance_eval(access_path)
        related_model.send(cell.attribute) if related_model.present?
      end
    end

    # Text Input
    def input_text_value(model, cell)
      if cell.accessor.nil?
        model.send(cell.attribute)
      else
        access_path = cell.accessor.join('.')
        related_model = model.instance_eval(access_path)
        related_model.send(cell.attribute) if related_model.present?
      end
    end

    # Personalize heading_text from steps.yml
    def personalize_heading_text(heading_text)
      if heading_text.include? '<family-member-name-placeholder>'

        first_name = if @model.is_a?(FinancialAssistance::Applicant)
                       @model.first_name
                     elsif @model.is_a?(FinancialAssistance::Application)
                       @model.primary_applicant.first_name
                     else
                       @model.first_name
                     end

        heading_text.sub! '<family-member-name-placeholder>', first_name.capitalize # rubocop:disable Style/NestedTernaryOperator TODO: Remove this
      else
        translation_placeholder_text(heading_text)
      end
    end

    # Edit state abbreviation placeholder
    def state_abbreviation_text(text)
      if text.include? '<state-abbreviation-placeholder>'
        text.sub! '<state-abbreviation-placeholder>', aca_state_abbreviation
      else
        text
      end
    end

    # TODO: All these Settings calls will have to be refactored for platformization
    def translation_placeholder_text(text)
      text.gsub! '<board_of_elections_address-placeholder>', Settings.contact_center.board_of_elections_address
      text.gsub! '<board_of_elections_email-placeholder>', Settings.contact_center.board_of_elections_email
      text.gsub! '<board_of_elections_entity-placeholder>', Settings.contact_center.board_of_elections_entity
      text.gsub! '<board_of_elections_phone_number-placeholder>', Settings.contact_center.board_of_elections_phone_number
      text.gsub! '<contact-center-phone_number-placeholder>', Settings.contact_center.phone_number
      text.gsub! '<medicaid-question-translation-placeholder>', state_abbreviation_text(l10n("faa.medicaid_question"))
      text.gsub! '<short-name-placeholder>', EnrollRegistry[:enroll_app].setting(:short_name).item
      text.gsub! '<state-abbreviation-placeholder>', aca_state_abbreviation
      text.gsub! '<reviewed-information>', l10n('insured.review_information')

      # Submit Your Application page
      text.gsub! '<submit-your-application>', l10n('faa.submit_your_application')
      text.gsub! '<last-step-1>', l10n('faa.last_step_1')
      text.gsub! '<last-step-2>', l10n('faa.last_step_2')
      text.gsub! '<i-understand-eligibility>', l10n('faa.i_understand_eligibility')
      text.gsub! '<renewal-process-1>', l10n('faa.renewal_process_1', short_name: EnrollRegistry[:enroll_app].setting(:short_name).item)
      text.gsub! '<renewal-process-2>', l10n('faa.renewal_process_2')
      text.gsub! '<send-notice-1>', l10n('faa.send_notice_1', short_name: EnrollRegistry[:enroll_app].setting(:short_name).item)
      text.gsub! '<send-notice-2>', l10n('faa.send_notice_2')
      text.gsub! '<send-notice-3>', l10n('faa.send_notice_3')
      text.gsub! '<i-agree>', l10n('faa.i_agree')
      text.gsub! '<i-understand-eligibility-changes>', l10n('faa.i_understand_eligibility_changes')
      text.gsub! '<report-changes-1>', l10n('faa.report_changes_1', short_name: EnrollRegistry[:enroll_app].setting(:short_name).item)
      text.gsub! '<report-changes-2>', l10n('faa.report_changes_2')
      text.gsub! '<signature-line-below-1>', l10n('faa.signature_line_below_1')
      text.gsub! '<signature-line-below-2>', l10n('faa.signature_line_below_2')
      text.gsub! '<i-understand-evaluation-1>', l10n('faa.i_understand_evaluation_1')
      text.gsub! '<i-understand-evaluation-2>', l10n('faa.i_understand_evaluation_2')
      text.gsub! '<i-understand-evaluation-3>', l10n('faa.i_understand_evaluation_3')
      text.gsub! '<anyone-found-eligible-1>', l10n('faa.anyone_found_eligible_1')
      text.gsub! '<anyone-found-eligible-2>', l10n('faa.anyone_found_eligible_2')
      text.gsub! '<anyone-found-eligible-3>', l10n('faa.anyone_found_eligible_3')
      text.gsub! '<parent-living-outside-of-home-1>', l10n('faa.parent_living_outside_of_home_1')
      text.gsub! '<parent-living-outside-of-home-2>', l10n('faa.parent_living_outside_of_home_2')
      text.gsub! '<parent-living-outside-of-home-3>', l10n('faa.parent_living_outside_of_home_3')

      text
    end

    # set YAML text placeholders
    def set_text_placeholders(text) # rubocop:disable Naming/AccessorMethodName
      return "" if text.nil?
      text.gsub! '<filing-as-head-placeholder>', l10n('faa.filing_as_head_of_household')
      # set application applicable year placeholder
      if text.include? '<application-applicable-year-placeholder>'
        text.sub! '<application-applicable-year-placeholder>', FinancialAssistanceRegistry[:enrollment_dates].setting(:application_year).item.constantize.new.call.value!.to_s
      else
        text
      end
    end

    def conditional_class?(line)
      if line.cells[1]&.attribute == "is_filing_as_head_of_household"
        return FinancialAssistanceRegistry.feature_enabled?(:filing_as_head_of_household) ? "hide filing-as-head-of-household" : ""
      end
      ""
    end

    def step_enabled?(section)
      return false if section.lines.first.cells.last.attribute == "full_medicaid_determination" && !FinancialAssistanceRegistry.feature_enabled?(:full_medicaid_determination_step)
      true
    end

    def line_enabled?(line)
      return false if line.cells[1]&.attribute == "is_filing_as_head_of_household" && !FinancialAssistanceRegistry.feature_enabled?(:filing_as_head_of_household)
      true
    end
  end
end
