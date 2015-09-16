class ShopNotices::EmployeeRenewalNotice < Notice

  def initialize(employee, args = {})
    super
    @employee = employee
    @to = "raghuramg83@gmail.com"
    @subject = "Employee Renewal notice"
    @template = "notices/renewal_1b.html.erb"
    build
  end

  def build
    @notice_data = {}
  end
end
