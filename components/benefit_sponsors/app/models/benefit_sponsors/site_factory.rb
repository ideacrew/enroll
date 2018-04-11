module BenefitSponsors
  class SiteFactory
    def build
      # possibly strip attributes of owner_org attributes and apply them to the org
      @site = BenefitSponsors::Site.new @form_obj.attributes
      @site.owner_organization = BenefitSponsors::Organizations::ExemptOrganization.new site: @site,
       legal_name: 'test'
      @site.owner_organization.profiles.build office_locations: [ 
        BenefitSponsors::Locations::OfficeLocation.new(
          address: BenefitSponsors::Locations::Address.new(address_1: '2nd St Nw',
                                                           city: 'Washington',
                                                           state: 'DC',
                                                           zip: '20001',
                                                           kind: 'primary'),
          phone: BenefitSponsors::Locations::Phone.new(area_code: '202', number: '555-2000', kind: 'work')
        )
      ]
      self
    end

    def initialize(form_obj)
      @form_obj = form_obj
    end

    def self.call(form_obj)
      new(form_obj).build
    end

    def self.find(user, id)
      @site = BenefitSponsors::Site.find(id.to_s)
    end

    def persist
      puts "valid: #{@site.owner_organization.profiles.first.valid?}"
      puts "errors: #{@site.owner_organization.profiles.first.errors.inspect}"
      @site.save && @site.owner_organization.save
    end

    def build_site

    end
  end
end