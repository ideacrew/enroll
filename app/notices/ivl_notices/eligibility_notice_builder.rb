class IvlNotices::EligibilityNoticeBuilder < IvlNotices::NoticeBuilder

  def initialize(consumer, hbx_enrollment_id)
    super(consumer, PdfTemplates::EligibilityNotice, {
      subject: "Eligibility for Health Insurance, Confirmation of Plan Selection",
      template: "notices/9cindividual.html.erb"
    })
    @hbx_enrollment_id = hbx_enrollment_id
  end

  def build
    super
    @family = @consumer.primary_family
    hbx_enrollments = @family.try(:latest_household).try(:hbx_enrollments).active rescue []  
    append_enrollments(hbx_enrollments)
  end

  def append_enrollments(hbx_enrollments)
    hbx_enrollment = hbx_enrollments.detect{|enrollment| enrollment.id == @hbx_enrollment_id}
    @notice.enrollments = build_enrollment(hbx_enrollment).to_a
    hbx_enrollments.reject{|hbx_enrollment| hbx_enrollment.id == @hbx_enrollment_id}.each do |hbx_enrollment|
      @notice.enrollments << build_enrollment(hbx_enrollment)
    end
  end
end