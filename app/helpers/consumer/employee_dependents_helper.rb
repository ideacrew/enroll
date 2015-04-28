module Consumer::EmployeeDependentsHelper
  def employee_dependent_submission_options_for(model)
    if model.persisted?
      { :remote => true, method: :put, :url => {:action => "new"}, :as => :dependent }
    else
      { :remote => true, method: :post, :url => {:action => "create"}, :as => :dependent }
    end
  end
end
