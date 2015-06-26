module Consumer::EmployeeRolesHelper
  def employee_role_submission_options_for(model)
    if model.persisted?
      { :url => consumer_employee_path(model), :method => :put }
    else
      { :url => consumer_employee_index_path, :method => :post }
    end
  end

  def coverage_relationship_check(offered_relationship_benefits=[], relationship)
    case relationship
    when "self"
      offered_relationship_benefits.include? "employee"
    when "spouse"
      offered_relationship_benefits.include? "spouse"
    when "life_partner"
      offered_relationship_benefits.include? "domestic_partner"
    when "child"
      offered_relationship_benefits.include? "child_under_26"
    else
      false
    end
  end
end
