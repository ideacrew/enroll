class IvlNotices::EligibilityNoticeBuilder < IvlNotices::NoticeBuilder

  def initialize(hbx_enrollment_id)
    super(PdfTemplates::EligibilityNotice, {
      template: "notices/ivl/9c_eligibility_confirmation_notification.html.erb"
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
  end

  def append_enrollments(hbx_enrollments)
    @notice.enrollments << build_enrollment(@hbx_enrollment)
    hbx_enrollments.reject{|hbx_enrollment| hbx_enrollment.id.to_s == @hbx_enrollment_id}.each do |hbx_enrollment|
      @notice.enrollments << build_enrollment(hbx_enrollment)
    end
  end
end