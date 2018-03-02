module SponsoredBenefits
  class Site
    include Mongoid::Document
    include Mongoid::Timestamps

    SITE_ID_MAX_LENGTH = 6

    attr_reader :subdomain, :site_id

    ## General settings for site

    # Unique, short identifier for this site
    field :site_id,     type: Symbol  # For example, :dc, :cca

    # Web site owner's formal agency or business name. Appear in formal locations, such as copyright attribution
    field :long_name,   type: String

    # Name for this Web site.  Used as title in web site header, system messages, notices, etc.
    field :short_name,  type: String

    # Site description or slogan that will appear on portal header
    field :byline,      type: String

    # The site's Worldwide Web base address (e.g. hbxshop.org)
    field :domain_name, type: String

    # The fully qualified domain name for the web site (e.g. https://enroll.mhc.hbxshop.org)
    field :home_url,    type: String

    # The fully qualified domain name for the web site's help index page (e.g. https://mhc.hbxshop.org/help)
    field :help_url,    type: String

    # The fully qualified domain name for the web site's Frequently Asked Questions index page (e.g. https://mhc.hbxshop.org/help)
    field :faqs_url,    type: String

    # The starting calendar year for reserving web site content copyright (year site became active)
    field :copyright_period_start,  type: String, default: ->{ ::TimeKeeper.date_of_record.year }

    # File name for the site's logo
    field :logo_file_name,  type: String # convention: site_id + "_logo.png"

    # TODO Deprecate logo file name and store as binary in database to support multitenancy
    field :logo,        type: BSON::Binary


    # TODO -- come up with scheme to manage/store these attributes and provide defaults
    field :colors,  type: Array

    has_one   :owner_organization,  class_name: "SponsoredBenefits::Organizations::Organization"
    has_many  :benefit_markets,     class_name: "SponsoredBenefits::BenefitMarkets::BenefitMarket"

    has_many  :organizations, as: :employer_profiles do
      SponsoredBenefits::Organizations::Organization.has_employer_profile
    end

    has_many  :organizations, as: :broker_agency_profiles do
      SponsoredBenefits::Organizations::Organization.has_broker_agency_profile
    end

    has_many  :organizations, as: :issuer_profiles do
      SponsoredBenefits::Organizations::Organization.has_issuer_profile
    end

    has_many  :organizations, as: :general_agencies do
      SponsoredBenefits::Organizations::Organization.has_general_agency_profile
    end

    # has_many :families,         class_name: "::Family"

    validates_presence_of :site_id, :owner_organization

    scope :find_by_site_id, ->(site_id) { where(site_id: site_id) }

    index({ site_id:  1 }, { unique: true })

    def subdomain
      site_id.to_s unless site_id.blank?
    end

    # Using a passed string, prepare and set a site identifier that meets validation requirements
    def site_id=(new_site_id)
      valid_id = scrub_site_id(new_site_id)

      if valid_id.present?
        write_attribute(:site_id, valid_id.to_sym)
      else
        site_id
      end
    end

    private

    # Valid IDs are less than or equal to SITE_ID_MAX_LENGTH characters, composed of letters and numbers only 
    # (no special characters), all lower case, and may not begin with a number    
    def scrub_site_id(new_site_id)
      return nil if new_site_id.numeric? || new_site_id.blank?
      strip_leading_numbers(new_site_id).parameterize.gsub(/[-_]/,'').slice(0, SITE_ID_MAX_LENGTH)
    end

    def strip_leading_numbers(input_string)
      while input_string.chr.numeric? do
        input_string = input_string.slice!(1, input_string.length - 1)
      end
      input_string
    end


  end
end
