# frozen_string_literal: true

class EmployeeRoster

  include RSpec::Matchers
  include Capybara::DSL

  def add_new_employee_btn
    '//a[contains(@class, "interaction-click-control-add-new-employee")]'
  end

  def upload_employee_roster_btn
    '//a[contains(@class, "interaction-click-control-upload-employee-roster")]'
  end

  def choose_file_btn
    '//input[@id="file"]'
  end

  def select_file_to_upload_btn
    '//label[@class="select btn btn-primary"]'
  end

  def upload_btn
    '//input[@class="btn btn-primary interaction-click-control-upload"]'
  end

  def download_employee_roster_btn
    '//a[@class="btn btn-default interaction-click-control-download-employee-roster"]'
  end

  def active_only_btn
    '//div[@id="Tab:active_alone"]'
  end

  def active_and_cobra_btn
    '//div[@id="Tab:active"]'
  end

  def cobra_only_btn
    '//div[@id="Tab:by_cobra"]'
  end

  def terminated_btn
    '//div[@id="Tab:terminated"]'
  end

  def all_btn
    '//div[@id="Tab:all"]'
  end

  def search
    '//input[@class="form-control input-sm"]'
  end

  def actions_btn
    '//button[@id="dropdown_for_census_employeeid_5f7e22391548433ba5868418"]'
  end

end