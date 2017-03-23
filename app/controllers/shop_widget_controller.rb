class ShopWidgetController < ApplicationController

  def home
    @conversion_widgets=ShopWidget::ShopConversionWidget.all
    @family_members=ShopWidget::ShopFamilyMembers.all
    @census_members=ShopWidget::ShopCensusMembers.all
    @employer_benefits=ShopWidget::ShopBenefits.all
    @employer_contribution=ShopWidget::EmployerContributions.all
    @plans=ShopWidget::Plans.all
    @brokers=ShopWidget::Brokers.all
    @total_policies=ShopWidget::ShopTotalPolicies.all
    @policies_by_month=ShopWidget::ShopPoliciesMonth.all
    @total_employers=ShopWidget::ShopOverallEmployers.all
  end


end