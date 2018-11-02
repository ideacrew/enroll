module Insured::PlanFilterHelper
  include L10nHelper

  def find_my_doctor
    if @market_kind == "individual" && @coverage_kind == "health"
      link_to('Find Your Doctor','',data: {toggle: "modal", target: "#plan_match_family"})
    elsif @market_kind == "shop" && @coverage_kind == "health"
      link_to('Find Your Doctor', 'https://dc.checkbookhealth.org/dcshopnationwide/', target: '_blank')
    end
  end

  def estimate_your_costs
    if @market_kind == "shop" && @coverage_kind == "health"
      link_to(l10n("estimate_your_costs"), @dc_checkbook_url , target: '_blank')
    end
  end

end
