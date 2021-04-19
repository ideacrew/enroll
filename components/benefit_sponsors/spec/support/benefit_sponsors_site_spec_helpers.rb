# frozen_string_literal: true

# TODO: We need to harmonize this into a single unified client site spec helper

require File.join(File.dirname(__FILE__), "client_site_spec_helpers/dc")
require File.join(File.dirname(__FILE__), "client_site_spec_helpers/cca")
require File.join(File.dirname(__FILE__), "client_site_spec_helpers/me")

module BenefitSponsors
  class SiteSpecHelpers
    const_name = EnrollRegistry[:enroll_app].setting(:site_key).item.upcase
    mod = const_get("BenefitSponsors::ClientSiteSpecHelpers::#{const_name}")
    extend mod
  end
end