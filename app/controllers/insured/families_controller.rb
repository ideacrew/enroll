class Insured::FamiliesController < FamiliesController

  def home
    @qualifying_life_events = QualifyingLifeEventKind.all
    @hbx_enrollments = @family.try(:latest_household).try(:hbx_enrollments).active || []
    @employee_role = @person.employee_roles.try(:first)

    respond_to do |format|
      format.html
    end
  end

  def manage_family
    @family_members = @family.active_family_members
    @qualifying_life_events = QualifyingLifeEventKind.all
    # @employee_role = @person.employee_roles.first

    respond_to do |format|
      format.html
      format.js
    end
  end

  def personal
    @family_members = @family.active_family_members
    respond_to do |format|
      format.html
      format.js
    end
  end

  def documents_index

  end

  def document_upload
    @consumer_wrapper = Forms::ConsumerRole.new(@person.consumer_role)
  end
end
