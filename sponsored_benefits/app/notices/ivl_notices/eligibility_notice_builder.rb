class IvlNotices::EligibilityNoticeBuilder < IvlNotices::NoticeBuilder

  def initialize(person_id, template_name=nil)
    template_obj = {}
    template_obj[:template] = template_name || "notices/ivl/9c_eligibility_confirmation_notification.html.erb"
    super(PdfTemplates::EligibilityNotice,template_obj)
    @person_id = person_id
    build
  end

  def build
    # @hbx_enrollment = HbxEnrollment.find(@hbx_enrollment_id)
    @consumer = Person.find(@person_id)
    super
    hbx_enrollments = @consumer.primary_family.active_household.hbx_enrollments.with_in(24.hours.ago)

    health = hbx_enrollments.select{|e| e.plan.market == 'individual' && e.plan.coverage_kind == 'health'}
    dental = hbx_enrollments.select{|e| e.plan.market == 'individual' && e.plan.coverage_kind == 'dental'}

    # @notice.enrollments << build_enrollment(health.first) if health.first
    # @notice.enrollments << build_enrollment(dental.first) if dental.first
    hbx_enrollments = [health.first, dental.first]

    append_enrollments(hbx_enrollments)
  end
end