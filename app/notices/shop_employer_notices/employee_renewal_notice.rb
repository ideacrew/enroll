class ShopNotices::EmployeeRenewalNotice < ShopNotice

  def initialize(employee, args = {})
    super(args)
    @employee = employee
    @to = @employee.try(:person).try(:home_email).try(:address)
    @subject = "Employee Renewal notice"
    @template = args[:template] || "notices/shop_notices/3a_employee_renewal.html.erb"
  end

  def deliver
    super
  end

  def build
    @notice = PdfTemplates::EmployeeNotice.new

    @notice.primary_fullname = @employee.person.full_name.titleize
    @notice.primary_identifier = @employee.person.hbx_id
    @notice.employer_name = @employee.employer_profile.try(:legal_name)
    if @employee.person.mailing_address.present?
      append_primary_address(@employee.person.mailing_address)
    else
      append_primary_address(@employee.new_census_employee.address)
    end
    @notice.email = @employee.person.user.email

    append_hbe
    append_broker(@employee.try(:employer_profile).try(:broker_agency_profile))

    plan_year = @employee.employer_profile.active_plan_year || @employee.employer_profile.latest_plan_year
    append_plan(plan_year)
  end

  def append_plan(plan_year)
    @notice.plan = PdfTemplates::Plan.new({
      open_enrollment_start_on: plan_year.open_enrollment_start_on,
      open_enrollment_end_on: plan_year.open_enrollment_end_on,
      coverage_start_on: plan_year.start_on,
      coverage_end_on: plan_year.end_on
    })
  end
end
