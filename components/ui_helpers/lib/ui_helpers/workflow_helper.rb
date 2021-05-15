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
        heading_text
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
      text.gsub! '<short-name-placeholder>', Settings.site.short_name
      text.gsub! '<state-abbreviation-placeholder>', aca_state_abbreviation
      text.gsub! '<reviewed-information>', l10n('insured.review_information')
      text
    end

    # set YAML text placeholders
    def set_text_placeholders(text) # rubocop:disable Naming/AccessorMethodName
      return "" if text.nil?
      # set application applicable year placeholder
      if text.include? '<application-applicable-year-placeholder>'
        text.sub! '<application-applicable-year-placeholder>', FinancialAssistanceRegistry[:enrollment_dates].setting(:application_year).item.constantize.new.call.value!.to_s
      else
        text
      end
    end
  end
end
