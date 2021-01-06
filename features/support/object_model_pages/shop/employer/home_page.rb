# frozen_string_literal: true

class EmployerHomePage

  include RSpec::Matchers
  include Capybara::DSL

  def my_employer_portal_link
    '//a[@class="header-text interaction-click-control-my-employer-portal"]'
  end

  def help_link
    '//a[@class="header-text interaction-click-control-help"]'
  end

  def logout_link
    '//a[@class="header-text interaction-click-control-logout"]'
  end

  def my_dc_health_link
    '//a[@class="interaction-click-control-my-dc-health-link"]'
  end

  def employees_link
    '(//a[@class="interaction-click-control-employees"])[1]'
  end

  def benefits_link
    '//a[@class="interaction-click-control-benefits"]'
  end

  def brokers_link
    '//a[@class="interaction-click-control-brokers"]'
  end

  def documents_link
    '//a[@class="interaction-click-control-documents"]'
  end

  def billing_link
    '//a[@class="interaction-click-control-billing"]'
  end

  def messages_link
    '//a[@class="hidden-xs interaction-click-control-messages1"]'
  end

  def update_business_info_link
    '//a[@class="interaction-click-control-update-business-info"]'
  end

  def view_enrollment_reports_link
    '//a[@class="interaction-click-control-view-enrollment-reports"]'
  end

  def my_employees_count_link
    '//a[contains(text(),"My Employees")]'
  end

  def add_broker_btn
    '//a[@class="btn btn-default center-block interaction-click-control-add-broker"]'
  end

  def what_is_a_broker_link
    '//a[@class="interaction-click-control-what-is-a-broker?"]'
  end
end