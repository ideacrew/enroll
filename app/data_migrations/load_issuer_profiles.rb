require File.join(Rails.root, "lib/mongoid_migration_task")

class LoadIssuerProfiles < MongoidMigrationTask

  def migrate
    issuer_profile_data = [
      {fein: "453416923", issuer_hios_ids: ["33653"], legal_name: "Community Health Options", abbreviation: "CHO", hbx_carrier_id: 30_001, ivl_health: true },
      {fein: "042452600", issuer_hios_ids: ["96667"], legal_name: "Harvard Pilgrim Health Care", abbreviation: "HPHC", hbx_carrier_id: 30_002, ivl_health: true },
      {fein: "470397286", issuer_hios_ids: ["76302"], legal_name: "Renaissance Dental", abbreviation: "RNSD", hbx_carrier_id: 30_003, ivl_dental: true },
      {fein: "311705652", issuer_hios_ids: ["48396"], legal_name: "Anthem Blue Cross and Blue Shield", abbreviation: "ANTHM", hbx_carrier_id: 30_004, ivl_health: true },
      {fein: "010286541", issuer_hios_ids: ["50165"], legal_name: "Northeast Delta Dental", abbreviation: "NEDD", hbx_carrier_id: 30_005, ivl_dental: true }
      # {fein: "234547586", issuer_hios_ids: ["41304"], legal_name: "AllWays Health Partners", abbreviation: "NHP", hbx_carrier_id: 20010, shop_health: true },
      # {fein: "800721489", issuer_hios_ids: ["59763"], legal_name: "Tufts Health Direct", abbreviation: "THPD", hbx_carrier_id: 20011, shop_health: true },
      # {fein: "042674079", issuer_hios_ids: ["29125"], legal_name: "Tufts Health Premier", abbreviation: "THPP", hbx_carrier_id: 20012, shop_health: true },
      # {fein: "362739571", issuer_hios_ids: ["31779"], legal_name: "UnitedHealthcare", abbreviation: "UHIC", hbx_carrier_id: 20014, shop_health: true },
      # {fein: "050513223", issuer_hios_ids: ["18076"], legal_name: "Altus Dental", abbreviation: "ALT", hbx_carrier_id: 20001, shop_dental: true },
      # {fein: "046143185", issuer_hios_ids: ["80538", "11821"], legal_name: "Delta Dental", abbreviation: "DDA", hbx_carrier_id: 20004, shop_dental: true }
    ]

    site_key = "me"
    site = BenefitSponsors::Site.find_or_create_by(site_key: site_key.to_sym)

    puts "*"*80 unless Rails.env.test?
    issuer_profile_data.each do |issuer_profile|

      fein = issuer_profile[:fein]
      legal_name = issuer_profile[:legal_name]
      abbreviation = issuer_profile[:abbreviation]
      hbx_carrier_id = issuer_profile[:hbx_carrier_id]
      issuer_hios_ids = issuer_profile[:issuer_hios_ids]
      ivl_health = issuer_profile[:ivl_health].present? ? true : false
      ivl_dental = issuer_profile[:ivl_dental].present? ? true : false
      shop_health = issuer_profile[:shop_health].present? ? true : false
      shop_dental = issuer_profile[:shop_dental].present? ? true : false

      exempt_organiation_params = {
        fein: fein,
        site_id: site.id,
        legal_name: legal_name
      }

      exempt_organization = BenefitSponsors::Organizations::ExemptOrganization.where(:"profiles.hbx_carrier_id" => hbx_carrier_id).first
      new_exempt_organization = if exempt_organization.present?
        exempt_organization
      else
        BenefitSponsors::Organizations::ExemptOrganization.new(exempt_organiation_params)
      end

      issuer_profile = new_exempt_organization.profiles.first
      if issuer_profile.present?
        puts "Carrier #{legal_name} already exists with this hbx_carrier_id #{hbx_carrier_id}." unless Rails.env.test?
      else
        office_location = BenefitSponsors::Locations::OfficeLocation.new(
          is_primary: true,
          address: {kind: "work", address_1: "address_placeholder", address_2: "address_2", city: "City", state: "St", zip: "10001" },
          phone: {kind: "main", area_code: "111", number: "111-1111"}
        )

        issuer_profile_params = {
          hbx_carrier_id: hbx_carrier_id,
          abbrev: abbreviation,
          ivl_health: ivl_health,
          ivl_dental: ivl_dental,
          shop_health: shop_health,
          shop_dental: shop_dental,
          issuer_hios_ids: issuer_hios_ids,
          office_locations: [office_location],
        }

        new_issuer_profile = BenefitSponsors::Organizations::IssuerProfile.new(issuer_profile_params)

        new_exempt_organization.profiles << new_issuer_profile
        new_exempt_organization.save

        puts "Successfully created #{legal_name} carrier with hbx_carrier_id #{hbx_carrier_id}" unless Rails.env.test?
      end
    end
    puts "*"*80 unless Rails.env.test?
  end

end