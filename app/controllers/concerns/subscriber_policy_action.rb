module SubscriberPolicyAction
  def execute_subscriber_policy_action
    # The "selected hbx enrollments" will be a string of mongo id's for hbx enrollments separated
    selected_hbx_enrollments = params["selected_hbx_enrollments"].gsub(/\s+/m, ' ').strip.split(" ")
    selected_action = params["subscriber_policy_action"]
    duped_params = params.dup
    family = 
    if selected_action == "add_sep"
      createSep # See sep_all.rb
      flash[:notice] = @message_for_partial # From createSep action
    elsif selected_action == 'cancel'
      # The cancel and termination will be tricky, the cancel and terminate
      # methods in the Bulk Actions for Admin class seems to allow dynamic params
      params_with_cancel_hbx = selected_hbx_enrollments.each_with_index do |val, index|
        duped_params["cancel_hbx_#{index}".to_sym] = val
      end
      ::Forms::BulkActionsForAdmin.new(duped_params).cancel_enrollments
      flash[:notice] = "Successfully canceled all family enrollments."
       
      # From HBX profiles controller
      # def create_eligibility
        # @element_to_replace_id = params[:person][:family_actions_id]
        # family = Person.find(params[:person][:person_id]).primary_family
        # family.active_household.create_new_tax_household(params[:person]) rescue nil
      # end
    elsif selected_action == "create_eligibility"
      # Logic needed
      # This method is called in household.rb
      family.primary_family.active_household.create_new_tax_household(params[:person])
      flash[:notice] = "Successfully created eligibility."
    elsif selected_action == "reinstate"
      # Logic needed
      flash[:notice] = "Successfully reinstated all family enrollments."
    elsif selected_action == "shorten_coverage_span"
      # Logic needed
      flash[:notice] = "Successfully shortened coverage span."
    elsif selected_action == "terminate"
      params_with_terminate_hbx = selected_hbx_enrollments.each_with_index do |val, index|
        params["terminate_hbx_#{index}".to_sym] = val
      end
      ::Forms::BulkActionsForAdmin.new(params_with_cancel_hbx).terminate_enrollments
      flash[:notice] = "Successfully terminated all family enrollments."
    else
      flash[:error] = "Please select a valid subscriber policy action type."
    end
  end
end