module Insured::PlanFilterHelper
  def find_my_doctor
    if @market_kind == "individual"
      link_to('Find Your Doctor', 'https://dc.checkbookhealth.org/dc/', target: '_blank')
    elsif @market_kind == "shop"
      link_to('Find Your Doctor', 'https://dc.checkbookhealth.org/dcshop/', target: '_blank')
    end
  end

  def estimate_your_costs
    if @market_kind == "shop" && @coverage_kind == "health"
      link_to('Estimate Your Costs', @dc_checkbook_url , target: '_blank')
    end
  end

end