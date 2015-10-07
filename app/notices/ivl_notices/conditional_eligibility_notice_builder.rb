class IvlNotices::ConditionalEligibilityNoticeBuilder < IvlNotices::NoticeBuilder

  def initialize(hbx_enrollment_id)
    super(PdfTemplates::ConditionalEligibilityNotice, {
      template: "notices/ivl/9f_conditional_eligibility_confirmation_notification.html.erb"
    })
    @hbx_enrollment_id = hbx_enrollment_id
  end

  def build
    @hbx_enrollment = HbxEnrollment.find(@hbx_enrollment_id)
    @consumer = @hbx_enrollment.subscriber.person
    super
    @family = @consumer.primary_family
    hbx_enrollments = @family.try(:latest_household).try(:hbx_enrollments).active rescue []  
    append_enrollments(hbx_enrollments)
    append_individuals(hbx_enrollments)
  end

  def append_individuals(hbx_enrollments)
    enrolled_members = []
    hbx_enrollments.each do |hbx_enrollment|
      enrolled_members += hbx_enrollment.hbx_enrollment_members.map(&:person)
    end
    enrolled_members.uniq.each do |person| 
      @notice.individuals << build_individual(person)
    end
  end

  def build_individual(person)
    params = { full_name: person.full_name }
    if consumer_role = person.consumer_role
      params.merge!({ 
        ssn_verified: consumer_role.ssn_verified?,
        citizenship_verified: consumer_role.citizenship_verified?,
        residency_verified: !consumer_role.residency_denied?,
        indian_conflict: consumer_role.indian_conflict?
      })
    end
    PdfTemplates::Individual.new(params)
  end
end