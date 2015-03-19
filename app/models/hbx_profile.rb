class HbxProfile
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Timestamps

  embedded_in :organization

  HbxName = "DC HealthLink"
  HbxCmsId = "DC0"

  ## Application-level caching

  # Directory::Carrier
  # hbx_id, hbx_carrier_id, name, abbrev, 

  # Directory::Plan
  # hbx_id, hbx_plan_id, hbx_carrier_id, hios_id, year, quarter, name, abbrev, market, type, metal_level, pdf

  # Directory::Premium

  ## Cross-reference ID Directory
  # Person
  # Employer
  # BrokerAgency
  # Policy

  ## IVL Market HBX Policies
  # Open Enrollment periods

  ## SHOP Market HBX Policies
  # Employer Contribution Strategies

  ShopRetroactiveTerminationMaximumInDays = 60
  ShopEnrollmentPeriodMaximumBeforeEligibilityInDays = 30
  ShopEnrollmentPeriodMinimumAfterRosterEntryInDays = 30

end

class HbxPolicyError < StandardError; end
