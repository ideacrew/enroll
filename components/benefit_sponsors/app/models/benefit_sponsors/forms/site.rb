module BenefitSponsors
  module Forms
    class Site
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :id, :site_key, :long_name, :short_name, :byline, :copyright_period_start, :site_organizations_count, :updated_at, :created_at

      validates :short_name, presence: true, :allow_blank => false
      validates :long_name, presence: true, :allow_blank => false

      def initialize(user, attributes={})
        @user = user
        assign_wrapper_attributes attributes
      end

      def assign_wrapper_attributes(attributes = {}, options={})
        if self.id = attributes.delete(:id)
          #find model with factory, set attributes with model.attributes
          assign_wrapper_attributes BenefitSponsors::SiteFactory.find(@user, id).attributes.except("_id"), protect: true
        end

         attributes.each_pair do |k, v|
          self.send("#{k}=", v) unless self.send(k) && options[:protect]
        end
      end

      def save
        return false unless self.valid?
        BenefitSponsors::SiteFactory.call(self).persist
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
