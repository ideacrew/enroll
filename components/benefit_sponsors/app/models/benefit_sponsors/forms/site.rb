module BenefitSponsors
  module Forms
    class Site
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :id, :site_key, :long_name, :short_name, :byline

      validates :short_name, presence: true, :allow_blank => false
      validates :long_name, presence: true, :allow_blank => false

      def initialize(user, attributes={})
        assign_attributes attributes
      end

      def assign_attributes(atts = {})
        atts.each_pair do |k, v|
          if k.to_sym == :id
            #find model with factory, set attributes with model.attributes
            assign_attributes BenefitSponsors::SiteFactory.find(v).attributes.except(:id)
          else
            self.send("#{k}||=".to_sym, v)
          end
        end
      end

      def save
        return false unless self.valid?
        factory_object = BenefitSponsors::SiteFactory.build attributes
      end

      def attributes
        { site_key: site_key,
          long_name: long_name,
          short_name: short_name,
          byline: byline }
      end

      private
      def assign_attributes(atts = {})
        atts.each_pair do |k, v|
          self.send("#{k}=".to_sym, v)
        end
      end
    end
  end
end
