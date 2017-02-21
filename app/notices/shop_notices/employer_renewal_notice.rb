class ShopNotices::EmployerRenewalNotice < ShopNotice

  attr_accessor :employer_profile

  def initialize(employer_profile,  args = {})
    super(args)
  end

  def deliver
    build
    super
  end

end 
