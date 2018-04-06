module BenefitSponsors
  module Forms
    module ProfileInformation

      def first_name=(val)
        @first_name = val.blank? ? nil : val.strip
      end

      def last_name=(val)
        @last_name = val.blank? ? nil : val.strip
      end

      def legal_name=(val)
        @legal_name = val.blank? ? nil : val.strip
      end

      def dob=(val)
        @dob = Date.strptime(val,"%Y-%m-%d") rescue nil
      end
      
      # Strip non-numeric characters
      def fein=(new_fein)
        @fein =  new_fein.to_s.gsub(/\D/, '') rescue nil
      end

      def office_locations_attributes=(attrs)
        @office_locations = []
        attrs.each_pair do |k, att_set|
          att_set.delete('phone_attributes') if att_set["phone_attributes"].present? && att_set["phone_attributes"]["number"].blank?
          @office_locations << Locations::OfficeLocation.new(att_set)
        end
        @office_locations
      end
    end
  end
end
