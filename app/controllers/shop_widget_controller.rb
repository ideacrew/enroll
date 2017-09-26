class ShopWidgetController < ApplicationController

  def home
    @total_employers_count=ShopWidget::ShopOverallEmployers.all
    @total_brokers_count=ShopWidget::Brokers.all
    @total_carriers_count=ShopWidget::Carriers.all
    @employer_contribution=ShopWidget::EmployerContributions.all
    @new_hire_benefits=ShopWidget::ShopBenefits.all
    @census_employees=ShopWidget::ShopCensusEmployees.all
    @shop_employees=ShopWidget::ShopEmployees.all
    @family_members=ShopWidget::ShopFamilyMembers.all
    @age_grps=ShopWidget::ShopAgeGroups.all
    @shop_genders=ShopWidget::ShopGenders.all
    @employee_status=ShopWidget::EmployeeStatus.all
  end

  def moreinfo

  end


end