class GenerateCcaSite < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "mhc"
      say_with_time("Creating CCA Site") do
        site = BenefitSponsors::Site.new(
          site_key: :mhc,
          byline: "The Right Place for the Right Plan",
          short_name: "Health Connector",
          domain_name: "hbxshop.org",
          long_name: "Massachusetts Health Connector")
        hbx = BenefitSponsors::Organizations::HbxProfile.new
        ol = OfficeLocation.new
        address = Address.new(kind: "work", address_1: "PO Box 960189", city: "Boston", state: "MA", zip: "02196")
        phone = Phone.new(kind: "main", area_code: "617", number: "9361037")
        ol.address = address
        ol.phone = phone
        hbx.office_locations << ol
        owner_organization = BenefitSponsors::Organizations::ExemptOrganization.new(legal_name: "owner_organization", site: site, profiles: [hbx])
        site.owner_organization = owner_organization
        site.save!
      end
    end
  end

  def self.down
    raise "Migration is not reversable."
  end
end
