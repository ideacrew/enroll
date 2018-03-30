module BenefitSponsors
  module BenefitApplications
    class AcaShopDcBenefitApplication < BenefitApplication

      # Sponsor self-reported number of full-time employees
      field :fte_count, type: Integer, default: 0

      # Sponsor self-reported number of part-time employess
      field :pte_count, type: Integer, default: 0

      # Sponsor self-reported number of Medicare Second Payers
      field :msp_count, type: Integer, default: 0


    end
  end
end
