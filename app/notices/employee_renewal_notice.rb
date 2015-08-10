class EmployeeRenewalNotice < ShopNotice

  def initialize(employee, args = {})
    super
    @employee = employee
    @to = "raghuramg83@gmail.com"
    @from = "no-reply@shop.dchealthlink.com"
    @subject = "Employee Renewal notice"
    @template = "user_mailer/welcome.text.erb"
    build
  end

  def build
    @locals = {}
  end
end








