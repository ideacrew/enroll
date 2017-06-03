module UIHelpers
  module WorkflowHelper
    def workflow_form_for(model, &block)
      path, method = if model.new_record?
        [controller.request.path.sub('new', 'step'), :post]
      else
        [controller.request.path.sub('new', "#{model.id}/step"), :put]
      end

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
      cell.value  == model.send(cell.attribute) ? true : false
    end

    # Dropdown
    def selected_value model, cell
      model.send(cell.attribute)
    end


    # Personalize heading_text from steps.yml
    def personalize_heading_text(heading_text)
      if (heading_text.include? '<family-member-name-placeholder>') && (@model.class.to_s == "FinancialAssistance::Applicant")
        heading_text.sub! '<family-member-name-placeholder>', @model.family_member.person.full_name
      end
    end

  end
end
