module Consumer::EmployeeDependentsHelper
  def employee_dependent_form_id(model)
    if model.persisted?
      "add_member_list_#{model.id}"
    else
      "new_employee_dependent_form"
    end
  end

  def employee_dependent_submission_options_for(model)
    if model.persisted?
      { :remote => true, method: :put, :url => {:action => "update"}, :as => :dependent, html: { multipart: true } }
    else
      { :remote => true, method: :post, :url => {:action => "create"}, :as => :dependent, html: { multipart: true } }
    end
  end
end
