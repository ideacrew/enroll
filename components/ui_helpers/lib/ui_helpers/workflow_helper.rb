module UIHelpers
  module WorkflowHelper

    def workflow_form_for(model, &block)
      path, method = if model.new_record?
        [controller.request.path.sub('new', 'step'), :post]
      else
        [controller.request.path.sub('new', "#{model.id}/step"), :put]
      end
      #path.gsub!(/\/\d$/, '')
      form_tag path, method: method do
        yield
      end
    end

    def previous_step_for
      controller.request.path + "/#{@current_step.to_i - 1}"
    end

    # The following helper methods are for populating the persisted values of each
    # attributes from the model during the construction of the HTML element.

    # Radio Button
    def radio_checked? model, cell
      cell.value  == model.send(cell.attribute) ? true : false if cell.attribute.present?
    end

    # Dropdown
    def selected_value model, cell
      if cell.accessor.nil?
        model.send(cell.attribute)
      else
        access_path = cell.accessor.join('.')
        related_model = model.instance_eval(access_path)
        related_model.send(cell.attribute) if related_model.present?
      end
    end

    # Text Input
    def input_text_value model, cell
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
      if (heading_text.include? '<family-member-name-placeholder>')
        heading_text.sub! '<family-member-name-placeholder>', (@model.class.to_s == "FinancialAssistance::Applicant" ? @model.family_member.person.first_name : (@model.class.to_s == "FinancialAssistance::Application" ? @model.primary_applicant.family_member.person.first_name : @applicant.family_member.person.first_name))
      else
        heading_text
      end
    end

  end
end
