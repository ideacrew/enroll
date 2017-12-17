module SponsoredBenefits
  module Organizations
    class AcaShopDcEmployerProfile < Profile

      embeds_one :general_agency_profile, cascade_callbacks: true, validate: true

    end
  end
end
