class IvlNotices::EligibilityDenialNoticeBuilder < IvlNotices::NoticeBuilder

  def initialize(consumer)
    super(PdfTemplates::ConditionalEligibilityNotice, {
      template: "notices/ivl/11_individual_total_ineligibility.html.erb"
    })
  end

  def build
    @hbx_enrollment = HbxEnrollment.find(@hbx_enrollment_id)
    @consumer = @hbx_enrollment.subscriber.person
    super
    @family = @consumer.primary_family
    hbx_enrollments = @family.try(:latest_household).try(:hbx_enrollments).active rescue []  
    append_individuals(hbx_enrollments)
  end
end