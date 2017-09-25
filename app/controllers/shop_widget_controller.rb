class ShopWidgetController < ApplicationController

  def home
    @total_employers_count=ShopWidget::ShopOverallEmployers.all
    @total_brokers_count=ShopWidget::Brokers.all
    @total_carriers_count=ShopWidget::Carriers.all
  end

  def moreinfo

  end


end