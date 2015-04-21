module Consumer::EmployeeRolesHelper
  def employee_role_submission_options_for(model)
    if model.persisted?
      { :url => consumer_employee_path(model), :method => :put, :remote => true }
    else
      { :url => consumer_employee_index_path, :method => :post, :remote => true }
    end
  end
end
