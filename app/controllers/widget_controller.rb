class WidgetController < ApplicationController

  def home
    @enrollments=ShopCovered::ShopEnrollmentsWidget.all
    @enrollments_monthly=ShopCovered::ShopEnrollmentsMonth.all
    @conversion_employees=ShopCovered::ShopConversionEmployees.all
    @gender_types=ShopCovered::ShopGenderTypes.all
    @overall_ages=ShopCovered::ShopOverallAges.all
    @total_status=ShopCovered::ShopStatusWidget.all
    @metal_types=ShopCovered::ShopMetalWidget.all
    @carriers=ShopCovered::ShopCarriersWidget.all
    # @annual_status=IvlCovered::AnnualStatusType.all
    # @age_groups=IvlCovered::OverallAgeGroups.all
    # @over_all_aptc=IvlCovered::OverallAptc.all
    # @overall_genders=IvlCovered::OverallGenderTypes.all
    # @annual_covered_lives=IvlCovered::AnnualCoveredLives.all
  end


end