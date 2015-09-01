class Insured::FamiliesController < FamiliesController

  before_action :init_qualifying_life_events, only: [:home, :manage_family, :find_sep]
  before_action :check_insured_role, only: [:home]
  # layout 'application', :only => :find_sep

  def home
    @hbx_enrollments = @family.enrolled_hbx_enrollments || []
    @employee_role = @person.employee_roles.try(:first)

    respond_to do |format|
      format.html
    end
  end

  def manage_family
    @family_members = @family.active_family_members
    # @employee_role = @person.employee_roles.first

    respond_to do |format|
      format.html
    end
  end

  def find_sep
    @hbx_enrollment_id = params[:hbx_enrollment_id]
    @market_kind = params[:market_kind]
    @coverage_kind = params[:coverage_kind]

    render :layout => 'application' 
  end

  def record_sep
    if params[:qle_id].present?
      qle = QualifyingLifeEventKind.find(params[:qle_id])
      special_enrollment_period = @family.special_enrollment_periods.new(effective_on_kind: params[:effective_on_kind])
      special_enrollment_period.selected_effective_on = Date.strptime(params[:effective_on_date], "%m/%d/%Y") if params[:effective_on_date].present?
      special_enrollment_period.qle_on = Date.strptime(params[:qle_date], "%m/%d/%Y")
      special_enrollment_period.qualifying_life_event_kind = qle
      special_enrollment_period.save
    end

    redirect_to group_selection_new_path(person_id: @person.id, consumer_role_id: @person.consumer_role.try(:id))
  end

  def personal
    @family_members = @family.active_family_members
    respond_to do |format|
      format.html
    end
  end

  def inbox
    @folder = params[:folder] || 'Inbox'
    @sent_box = false
  end
  
  def documents_index

  end

  def document_upload
    @consumer_wrapper = Forms::ConsumerRole.new(@person.consumer_role)
  end

  private
  def init_qualifying_life_events
    @qualifying_life_events = []
    if @person.employee_roles.present?
      @qualifying_life_events += QualifyingLifeEventKind.shop_market_events
    elsif @person.consumer_role.present?
      @qualifying_life_events += QualifyingLifeEventKind.individual_market_events
    end
  end

  def check_insured_role
    if session[:portal].include?("insured/families")
      return true if current_user.has_employee_role? || current_user.has_consumer_role?
      flash[:error] = "You are not authorized to visit this portal."
      redirect_to root_path and return
    end
  end
end
