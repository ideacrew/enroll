class ShopWidgetController < ApplicationController

  def home
    @total_employers_count=ShopWidget::ShopOverallEmployers.all
    @total_brokers_count=ShopWidget::Brokers.all
  end

  def moreinfo

  end


end