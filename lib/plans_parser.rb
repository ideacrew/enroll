class PlansParser

  include HappyMapper
  tag 'planAttributes'
  element :name, String, :tag => "planMarketingName"
  element :metal_level, String, :tag => "metalLevel"
  element :active_year, Date, :tag => "planEffectiveDate"
  element :standard_component_id, String, :tag => "standardComponentID"
  element :hpid, String
  element :serviceAreaID, String
  element :formularyID, String
  element :isNewPlan, String
  element :planType, String
  element :metalLevel, String
  element :uniquePlanDesign, String
  element :qhpOrNonQhp, String
  element :insurancePlanPregnancyNoticeReqInd, String
  element :isSpecialistReferralRequired, String
  element :healthCareSpecialistReferralType, String
  element :insurancePlanBenefitExclusionText, String
  element :indianPlanVariation, String
  element :hsaEligibility, String
  element :employerHSAHRAContributionIndicator, String
  element :empContributionAmountForHSAOrHRA, String
  element :childOnlyOffering, String
  element :childOnlyPlanID, String
  element :isWellnessProgramOffered, String
  element :isDiseaseMgmtProgramsOffered, String
  element :ehbApportionmentForPediatricDental, String
  element :guaranteedVsEstimatedRate, String
  element :maximumCoinsuranceForSpecialtyDrugs, String
  element :maxNumDaysForChargingInpatientCopay, String
  element :beginPrimaryCareCostSharingAfterSetNumberVisits, String
  element :beginPrimaryCareDeductibleOrCoinsuranceAfterSetNumberCopays, String
  element :planEffectiveDate, String
  element :planExpirationDate, String
  element :outOfCountryCoverage, String
  element :outOfCountryCoverageDescription, String
  element :outOfServiceAreaCoverage, String
  element :outOfServiceAreaCoverageDescription, String
  element :nationalNetwork, String
  element :summaryBenefitAndCoverageURL, String
  element :enrollmentPaymentURL, String
  element :planBrochure, String
end