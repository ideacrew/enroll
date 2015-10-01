class IvlNotices::NoticeBuilder

  attr_reader :notice, :consumer, :subject, :template, :builder_template
  
  def initialize(builder_template, options={})
    @template = options[:template]
    @subject = options[:subject]
    @builder_template = builder_template
  end

  def build
    @notice = @builder_template.new
    @notice.primary_fullname = @consumer.full_name.titleize
    @notice.primary_identifier = @consumer.hbx_id
    append_mailing_address(@consumer.mailing_address)
  end

  def append_mailing_address(mailing_address)
    @notice.primary_address = PdfTemplates::NoticeAddress.new({
      street_1: mailing_address.address_1.titleize,
      street_2: mailing_address.address_2.titleize,
      city: mailing_address.city.titleize,
      state: mailing_address.state,
      zip: mailing_address.zip
    })
  end

  def build_enrollment(hbx_enrollment)
    PdfTemplates::Enrollment.new({
      plan_name: hbx_enrollment.plan.name,
      premium: hbx_enrollment.total_premium,
      phone: hbx_enrollment.phone_number,
      effective_on: hbx_enrollment.effective_on,
      selected_on: hbx_enrollment.created_at,
      enrollees: hbx_enrollment.hbx_enrollment_members.inject([]) do |names, member| 
        names << member.person.full_name.titleize
      end
    })
  end

  def generate_pdf_notice
    ivl_notice = IvlPdfNotice.new
    ivl_notice.notice = @notice
    ivl_notice.template = @template
    ivl_notice.create
  end
end