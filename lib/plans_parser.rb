class PlansParser
  
  PARSER_ELEMENTS = ["name","metal_level","active_year","standard_component_id","hpid","serviceAreaID","formularyID",
"isNewPlan","planType","metalLevel","uniquePlanDesign","qhpOrNonQhp","insurancePlanPregnancyNoticeReqInd","isSpecialistReferralRequired","healthCareSpecialistReferralType","insurancePlanBenefitExclusionText","indianPlanVariation","hsaEligibility","employerHSAHRAContributionIndicator","empContributionAmountForHSAOrHRA","childOnlyOffering","childOnlyPlanID","isWellnessProgramOffered","isDiseaseMgmtProgramsOffered",
"ehbApportionmentForPediatricDental","guaranteedVsEstimatedRate","maximumCoinsuranceForSpecialtyDrugs","maxNumDaysForChargingInpatientCopay",
"beginPrimaryCareCostSharingAfterSetNumberVisits","beginPrimaryCareDeductibleOrCoinsuranceAfterSetNumberCopays","planEffectiveDate","planExpirationDate","outOfCountryCoverage","outOfCountryCoverageDescription","outOfServiceAreaCoverage",
"outOfServiceAreaCoverageDescription","nationalNetwork","summaryBenefitAndCoverageURL","enrollmentPaymentURL","planBrochure"]

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