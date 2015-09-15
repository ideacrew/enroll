class IvlNotices::EligibilityNoticeBuilder < Notice

  attr_reader :notice

  def initialize(consumer, args = {})
    super
    @consumer = consumer
    @to = (@consumer.home_email || @consumer.work_email).address
    @subject = "Eligibility for Health Insurance, Confirmation of Plan Selection"
    @template = "notices/9cindividual.html.erb"
    build
  end

  def build
    #family = @consumer.primary_family
    @family = Family.find_by_primary_applicant(@consumer)
    @hbx_enrollments = @family.try(:latest_household).try(:hbx_enrollments).active rescue []
    @notice = PdfTemplates::EligibilityNotice.new
    @notice.primary_fullname = @consumer.full_name.titleize
    @notice.primary_identifier = @consumer.hbx_id
    append_address(@consumer.addresses[0])
    append_enrollments(@hbx_enrollments)
  end

  def append_address(primary_address)
    @notice.primary_address = PdfTemplates::NoticeAddress.new({
      street_1: primary_address.address_1.titleize,
      street_2: primary_address.address_2.titleize,
      city: primary_address.city.titleize,
      state: primary_address.state,
      zip: primary_address.zip
      })
  end

  def append_enrollments(hbx_enrollments)
    hbx_enrollments.each do |hbx_enrollment|
      @notice.enrollments << PdfTemplates::Enrollment.new({
        plan_name: hbx_enrollment.plan.name,
        monthly_premium_cost: hbx_enrollment.total_premium,
        phone: hbx_enrollment.phone_number,
        effective_on: hbx_enrollment.effective_on,
        enrollees: hbx_enrollment.hbx_enrollment_members.inject([]) do |names, member| 
          names << member.person.full_name.titleize
        end
        }) 
    end 
  end
end
