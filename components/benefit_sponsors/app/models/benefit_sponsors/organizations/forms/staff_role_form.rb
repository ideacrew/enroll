module BenefitSponsors
  module Organizations
    class Forms::StaffRoleForm
      include ActiveModel::Validations
      include Virtus.model

      attribute :npn, String
      attribute :first_name, String
      attribute :last_name, String
      attribute :email, String
      attribute :dob, String
      attribute :person_id, String
      attribute :area_code, String
      attribute :number, String
      attribute :extension, String

      attribute :profile_type, String

      validates_presence_of :dob, :if => Proc.new { |m| m.person_id.blank? }
      validates_presence_of :first_name, :if => Proc.new { |m| m.person_id.blank? }
      validates_presence_of :last_name, :if => Proc.new { |m| m.person_id.blank? }

      def persisted?
        false
      end

      def first_name=(val)
        @first_name = val.blank? ? nil : val.strip
      end

      def last_name=(val)
        @last_name = val.blank? ? nil : val.strip
      end

      def dob=(val)
        @dob = Date.strptime(val,"%m/%d/%Y") rescue nil
      end

      def is_broker_profile?
        profile_type == "broker_agency"
      end

      def is_employer_profile?
        profile_type == "benefit_sponsor"
      end
    end
  end
end
