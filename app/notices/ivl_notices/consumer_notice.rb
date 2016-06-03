class IvlNotices::ConsumerNotice < IvlNotice

  def initialize(consumer_role, args = {})
    super(args)

    @template = args[:template]
    @delivery_method = args[:delivery_method].split(',')
    @recipient = consumer_role.person
    @secure_message_recipient = consumer_role.person
    @notice = PdfTemplates::ConditionalEligibilityNotice.new
    @market_kind = 'individual'

    # @to = @recipient.home_email.address
    # @email_notice = args[:email_notice] || true
    # @paper_notice = args[:paper_notice] || true
  end

  def build
    @family = @recipient.primary_family    
    @notice.primary_fullname = @recipient.full_name.titleize
    @notice.primary_identifier = @recipient.hbx_id
    append_address(@recipient.mailing_address)

    append_unverified_family_members
  end

  def append_unverified_family_members
    enrollments = @family.active_household.hbx_enrollments.where('aasm_state' => 'enrolled_contingent').order(created_at: :desc).to_a
    
    if enrollments.empty?
      raise "enrollment don't exists!!"
    end

    @notice.enrollments << enrollments.first

    family_members = enrollments.inject([]) do |family_members, enrollment|
      family_members += enrollment.hbx_enrollment_members.map(&:family_member)
    end.uniq

    people = family_members.map(&:person).uniq
    people.reject!{|person| person.consumer_role.blank? || person.consumer_role.outstanding_verification_types.compact.blank? }

    append_unverified_individuals(people)
    @notice.due_date = (enrollments.first.special_verification_period || (enrollments.first.created_at + 95.days)).strftime("%m/%d/%Y")
  end

  def verification_type_outstanding?(person, verification_type)
    verification_pending = false
    if person.verification_types.include?(verification_type)
      if person.consumer_role.is_type_outstanding?(verification_type)
        verification_pending = true
      end
    end
    verification_pending
  end

  def append_unverified_individuals(people)
    people.each do |person|
      if verification_type_outstanding?(person, 'Social Security Number')
        @notice.ssa_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize })
      end

      if verification_type_outstanding?(person, 'Citizenship') || verification_type_outstanding?(person, 'Immigration status')
        @notice.dhs_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize })
      end
    end
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
end 