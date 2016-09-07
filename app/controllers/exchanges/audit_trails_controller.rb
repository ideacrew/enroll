class Exchanges::AuditTrailsController < ApplicationController

  def index
    @p = Person.new(last_name: "tracker", first_name: "history")
    # @trackers = ActionJournal.limit(25)
    # @changes = @trackers.first.tracked_changes
    # @edits = @trackers.first.tracked_edits

    @trackers = ActionJournal.limit(25)
  end

  def consumer_role
    @consumer_role = ConsumerRole.find(params[:consumer_role])
    @consumer_role_history = @consumer_role.history_tracks
    # @consumer_role_changes = @consumer_role.tracked_changes
    # @consumer_role_edits = @consumer_role.tracked_edits
  end

  def employee_role
    @employee_role = EmployeeRole.find(params[:employee_role])
    @employee_role_history = @employee_role.history_tracks
    # @employee_role_changes = @employee_role.tracked_changes
    # @employee_role_edits = @employee_role.tracked_edits
  end

  def family
    @family = Family.find(params[:family])
    @family_changes = @family.tracked_changes
    @family_edits = @family.tracked_edits
  end

  def employer_profile
    @employer_profile = EmployerProfile.find(params[:employer_profile])
    @employer_profile_changes = @employer_profile.tracked_changes
    @employer_profile_edits = @employer_profile.tracked_edits
  end

end
