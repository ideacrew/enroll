class Hbx
  include Mongoid::Document
  include Mongoid::Versioning
  include Mongoid::Timestamps

  HBX_ID = "DC0"

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

end
