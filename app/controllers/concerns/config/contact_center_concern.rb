module Config::ContactCenterConcern
  def contact_center_phone_number
    EnrollRegistry[:enroll_app].setting(:health_benefit_exchange_authority_phone_number)&.item
  end
end
