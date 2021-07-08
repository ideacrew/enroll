require File.join(File.dirname(__FILE__), "client_contribution_model_spec_helpers/cca")
require File.join(File.dirname(__FILE__), "client_contribution_model_spec_helpers/dc")
require File.join(File.dirname(__FILE__), "client_contribution_model_spec_helpers/me")

module BenefitSponsors
  class ContributionModelSpecHelpers
    const_name = EnrollRegistry[:enroll_app].setting(:site_key).item.upcase
    mod = const_get("BenefitSponsors::ClientContributionModelSpecHelpers::#{const_name}")
    extend mod
  end
end