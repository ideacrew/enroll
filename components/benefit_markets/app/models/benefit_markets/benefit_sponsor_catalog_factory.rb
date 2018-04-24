module BenefitMarkets
  class BenefitSponsorCatalogFactory

    attr_reader :benefit_catalog, :service_area

    def self.call(effective_date, benefit_catalog, service_area=nil)
      new(effective_date, benefit_catalog, service_area).benefit_sponsor_catalog
    end

    def initialize(effective_date, benefit_catalog, service_area=nil)
      @benefit_catalog = benefit_catalog
      @service_area    = service_area
      @benefit_sponsor_catalog = BenefitMarkets::BenefitSponsorCatalog.new

      add_probation_period_options
      add_eligibilities
      add_product_packages
    end

    def add_probation_period_options
      @benefit_sponsor_catalog.probation_period_options = benefit_catalog.probation_period_kinds
    end

    def add_eligibilities
      @benefit_sponsor_catalog.eligibilities = []
    end
    
    def add_product_packages
      @benefit_sponsor_catalog.product_packages = benefit_catalog.product_packages_for(service_area)
    end

    def benefit_sponsor_catalog
      @benefit_sponsor_catalog
    end
  end
end




