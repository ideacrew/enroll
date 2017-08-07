module Insured::PlanFilterHelper
  def find_my_doctor
    if @market_kind == "individual"
      link_to('Find Your Doctor', 'https://dc.checkbookhealth.org/dc/', target: '_blank')
    elsif @market_kind == "shop"
      link_to('Find Your Doctor', Settings.site.shop_find_your_doctor_url , target: '_blank')
    end
  end
end