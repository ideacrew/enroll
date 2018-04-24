module BenefitMarkets
    class BenefitMarketForm
      include ActiveModel::Model
      include ActiveModel::Validations


      attr_accessor :site_urn
      attr_accessor :kind
      attr_accessor :title
      attr_accessor :description

      attr_reader :show_page_model

      validates_presence_of :title, :allow_blank => false
      validates_presence_of :site_urn, :allow_blank => false
      validates_presence_of :kind, :allow_blank => false
      validates_inclusion_of :benefit_market_kind, :in => :allowed_benefit_market_kinds, :allow_blank => false
  
      def allowed_benefit_markets_kinds
        benefit_market_factory.allowed_benefit_market_kinds
      end

      def self.form_for_new(benefit_market_kind)
        resolve_form_subclass(benefit_market_kind).new(
          :benefit_market_kind => benefit_market_kind,
          :benefit_market_factory => ::BenefitMarkets::BenefitMarketFactory.new(benefit_market_kind)
        )
      end

      def self.form_for_create(opts)
        benefit_market_kind = opts.require(:benefit_market_kind)
        resolve_form_subclass(benefit_market_kind).new(
          opts.merge({:benefit_market_factory => ::BenefitMarkets::BenefitMarketFactory.new(benefit_market_kind), benefit_market_kind: benefit_market_kind})
        )
      end

      def self.resolve_form_subclass(benefit_market_kind)
        name_parts = benefit_market_kind.to_s.split("_")
        benefit_market_kind = name_parts.last
        "::BenefitMarkets::#{benefit_market_kind.to_s.camelcase}BenefitPackageForm".constantize
      end

      def build_object_using_factory
        benefit_market_factory.build_benefit_package(
          site_urn,
          kind,
          title
        )
      end

      def has_additional_attributes?
        false
      end

      def save
        return false unless self.valid?
        factory_object = build_object_using_factory
        @show_page_model = factory_object
        benefit_market_factory.persist(factory_object, self)
      end
    end
  end
end
