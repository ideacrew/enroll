module BenefitSponsors
  module Organizations
    class Forms::OrganizationForm
      include ActiveModel::Validations
      include ::Validations::Email
      include BenefitSponsors::Forms::NpnField
      extend  ActiveModel::Naming
      include ActiveModel::Conversion
      include Virtus.model

      attribute :fein, String
      attribute :legal_name, String
      attribute :dba, String

      attribute :profile, Forms::ProfileForm


      validates :fein,
        length: { is: 9, message: "%{value} is not a valid FEIN" },
        numericality: true

      validates_presence_of :fein, :legal_name

      def persisted?
        false
      end

      def legal_name=(val)
        legal_name = val.blank? ? nil : val.strip
        super legal_name
      end
      
      # Strip non-numeric characters
      def fein=(new_fein)
        fein =  new_fein.to_s.gsub(/\D/, '') rescue nil
        super fein
      end

      def profile_attributes=(profile_params)
        self.profile=(profile_params)
      end

      def profile=(val)
        result = super val
        result.parent = self
        result
      end
    end
  end
end
