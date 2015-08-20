class EligibilityNoticeBuilder < Notice

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
    family = @consumer.primary_family
    hbx_enrollments = family.try(:latest_household).try(:hbx_enrollments).active || []
    @notice = PdfTemplates::EligibilityNotice.new
    @notice.primary_fullname = @consumer.full_name.titleize
    append_address
    append_enrollments(hbx_enrollments)
  end

  def append_address
    primary_address = @consumer.addresses[0]
    address = PdfTemplates::NoticeAddress.new
    address.street_1 = primary_address.address_1.titleize
    address.street_2 = primary_address.address_2.titleize
    address.city = primary_address.city.titleize
    address.state = primary_address.state
    address.zip = primary_address.zip
    @notice.primary_address = address
  end

  def append_enrollments(hbx_enrollments)
    hbx_enrollments.each do |hbx_enrollment|
      enrollment = PdfTemplates::Enrollment.new 
      enrollment.plan_name = hbx_enrollment.plan.name
      enrollment.enrollees = hbx_enrollment.hbx_enrollment_members.map(&:person).inject([]) do |names, person| 
        names << person.full_name.titleize
      end
      enrollment.monthly_premium_cost = hbx_enrollment.total_premium
      @notice.enrollments << enrollment
    end  
  end
end