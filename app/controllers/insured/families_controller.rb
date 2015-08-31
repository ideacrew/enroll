class Insured::FamiliesController < FamiliesController

  before_action :init_qualifying_life_events, only: [:home, :manage_family, :find_sep]
  layout 'application', :only => :find_sep

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
end
