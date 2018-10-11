module Insured::PlanFilterHelper
  include L10nHelper

  def find_my_doctor
    if @market_kind == "individual"
      link_to('Find Your Doctor', 'https://dc.checkbookhealth.org/dc/', target: '_blank')
    elsif @market_kind == "shop"
      link_to('Find Your Doctor', 'https://dc.checkbookhealth.org/dcshop/', target: '_blank')
    end
  end


  def checkbook_integration
    if @market_kind == "individual"
      link_to('Estimate Your Costs', 'https://staging.checkbookhealth.org/hie/dc/api/', target: '_blank')
    end
  end


  def estimate_your_costs
    if @market_kind == "shop" && @coverage_kind == "health"
      link_to(l10n("estimate_your_costs"), @dc_checkbook_url , target: '_blank')
    end
  end

end
