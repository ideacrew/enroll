require File.join(File.dirname(__FILE__), "client_organization_spec_helpers/dc")
require File.join(File.dirname(__FILE__), "client_organization_spec_helpers/me")

module BenefitSponsors
  class OrganizationSpecHelpers
    const_name = EnrollRegistry[:enroll_app].setting(:site_key).item.upcase
    mod = const_get("BenefitSponsors::ClientOrganizationSpecHelpers::#{const_name}")
    extend mod
  end
end