class ShopWidgetController < ApplicationController

  def home
    @conversion_widgets=ShopWidget::ShopConversionWidget.all
    # @enrollments_monthly=ShopCovered::ShopEnrollmentsMonth.all
    # @conversion_employees=ShopCovered::ShopConversionEmployees.all
    # @gender_types=ShopCovered::ShopGenderTypes.all
    # @overall_ages=ShopCovered::ShopOverallAges.all
    # @total_status=ShopCovered::ShopStatusWidget.all
    # @metal_types=ShopCovered::ShopMetalWidget.all
    # @carriers=ShopCovered::ShopCarriersWidget.all
    # @total_widgets=ShopCovered::ShopTotalEnrollments.all
  end


end