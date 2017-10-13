class IvlNotices::ConsumerNotice < IvlNotice
  attr_accessor :family

  def initialize(consumer_role, args = {})
    args[:recipient] = consumer_role.person
    args[:notice] = PdfTemplates::ConditionalEligibilityNotice.new
    args[:market_kind] = 'individual'
    args[:recipient_document_store]= consumer_role.person
    args[:to] = consumer_role.person.work_email_or_best
    self.header = "notices/shared/header_ivl.html.erb"
    super(args)
  end

  def deliver
    build
    generate_pdf_notice
    attach_envelope
    attach_blank_page(notice_path)
    attach_required_documents if (notice.documents_needed && !notice.cover_all?) 
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def attach_envelope
  end

  def attach_required_documents
    generate_custom_notice('notices/ivl/documents_section')
    attach_blank_page(custom_notice_path)
    join_pdfs [notice_path, custom_notice_path]
    clear_tmp
  end

  def build
    family = recipient.primary_family    
    notice.mpi_indicator = self.mpi_indicator
    notice.primary_fullname = recipient.full_name.titleize || ""
    notice.first_name = recipient.first_name
    append_hbe
    if recipient.mailing_address
      append_address(recipient.mailing_address)
    else  
      raise 'mailing address not present'
    end
    append_unverified_family_members
  end

  def append_unverified_family_members
    family = recipient.primary_family
    enrollments = family.households.flat_map(&:hbx_enrollments).select do |hbx_en|
      (!hbx_en.is_shop?) && (!["coverage_canceled", "shopping", "inactive"].include?(hbx_en.aasm_state)) &&
        (
          hbx_en.terminated_on.blank? ||
          hbx_en.terminated_on >= TimeKeeper.date_of_record
        )
    end
    enrollments.reject!{|e| e.coverage_terminated? }
    if enrollments.empty?
      raise 'enrollments not found!'
    end
    family_members = enrollments.inject([]) do |family_members, enrollment|
      family_members += enrollment.hbx_enrollment_members.map(&:family_member)
    end.uniq
    people = family_members.map(&:person).uniq
    people.reject!{|p| p.consumer_role.aasm_state != 'verification_outstanding'}
    people.reject!{|person| !ssn_outstanding?(person) && !lawful_presence_outstanding?(person) }
    if people.empty?
      raise 'no family member found with outstanding verification'
    end
    
    outstanding_people = []
    people.each do |person|
      if person.consumer_role.outstanding_verification_types.present?
        outstanding_people << person
      end
    end

    outstanding_people.uniq!
    if outstanding_people.empty?
      raise 'no family member found without uploaded documents'
    end
    # enrollments.each {|e| e.update_attributes(special_verification_period: Date.today + 95.days)}
    contingent_enrollment = enrollments.detect{ |e | e.enrolled_contingent? }
    notice.enrollments << build_enrollment(contingent_enrollment)
    notice.documents_needed = outstanding_people.present? ? true : false
    notice.due_date = family.min_verification_due_date rescue ""
    notice.application_date = contingent_enrollment.created_at  rescue ""
    # family.update_attributes(min_verification_due_date: family.min_verification_due_date_on_family)
    append_unverified_individuals(outstanding_people)
    notice.primary_identifier = contingent_enrollment.id
  end

   def build_enrollment(hbx_enrollment)
    PdfTemplates::Enrollment.new({
      plan_name: hbx_enrollment.plan.name ,
      premium: hbx_enrollment.total_premium,
      phone: hbx_enrollment.phone_number,
      effective_on: hbx_enrollment.effective_on,
      selected_on: hbx_enrollment.created_at,
      is_receiving_assistance: (hbx_enrollment.applied_aptc_amount > 0 || hbx_enrollment.plan.is_csr?) ? true : false,
      # enrollees: hbx_enrollment.hbx_enrollment_members.inject([]) do |names, member|
      #   names << member.person.full_name.titleize
      # end
    })
  end

  def ssn_outstanding?(person)
    person.consumer_role.outstanding_verification_types.include?("Social Security Number")
  end

  def lawful_presence_outstanding?(person)
    person.consumer_role.outstanding_verification_types.include?('Citizenship') || person.consumer_role.outstanding_verification_types.include?('Immigration status')
  end

  def append_unverified_individuals(people)
    people.each do |person|
      if ssn_outstanding?(person)
        notice.ssa_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: notice.due_date, age: person.age_on(TimeKeeper.date_of_record) })
      end

      if lawful_presence_outstanding?(person)
        notice.dhs_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: notice.due_date, age: person.age_on(TimeKeeper.date_of_record) })
      end
    end
  end

  def append_address(primary_address)
    notice.primary_address = PdfTemplates::NoticeAddress.new({
      street_1: capitalize_quadrant(primary_address.address_1.to_s.titleize),
      street_2: capitalize_quadrant(primary_address.address_2.to_s.titleize),
      city: primary_address.city.titleize,
      state: primary_address.state,
      zip: primary_address.zip
      })
  end

  def append_hbe
    notice.hbe = PdfTemplates::Hbe.new({
      url: Settings.site.home_url,
      phone: phone_number_format(Settings.contact_center.phone_number),
      email: Settings.contact_center.email_address,
      short_url: "#{Settings.site.short_name.gsub(/[^0-9a-z]/i,'').downcase}.com",
    })
  end

  def capitalize_quadrant(address_line)
    address_line.split(/\s/).map do |x| 
      x.strip.match(/^NW$|^NE$|^SE$|^SW$/i).present? ? x.strip.upcase : x.strip
    end.join(' ')
  end

  def to_csv
    [
      recipient.hbx_id,
      recipient.first_name,
      recipient.last_name,
      notice.primary_address.present? ? notice.primary_address.attributes.values.reject{|x| x.blank?}.compact.join(',') : "",
      notice.due_date,
      (notice.enrollments.first.submitted_at || notice.enrollments.first.created_at),
      notice.enrollments.first.effective_on,
      notice.ssa_unverified.map{|individual| individual.full_name }.join(','),
      notice.dhs_unverified.map{|individual| individual.full_name }.join(','),
      recipient.consumer_role.contact_method,
      recipient.home_email.try(:address) || recipient.user.try(:email),
      notice.enrollments.first.aasm_state.to_s
    ]
  end
end 