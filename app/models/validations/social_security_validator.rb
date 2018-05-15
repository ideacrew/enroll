module Validations
  class SocialSecurityValidator < ActiveModel::Validator

    attr_reader :ssn

    def validate(obj)
      # Invalid compositions:
      #   All zeros or 000, 666, 900-999 in the area numbers (first three digits);
      #   00 in the group number (fourth and fifth digit); or
      #   0000 in the serial number (last four digits)
      @ssn = obj.ssn

      if ssn.present?
        obj.errors.add(:ssn, 'is invalid') if is_ssn_invalid? || is_ssn_sequential? || is_ssn_has_same_number?
      end
    end

    private

    def is_ssn_invalid?
      invalid_area_numbers = %w(000 666)
      # invalid_area_range = 900..999
      invalid_group_numbers = %w(00)
      invalid_serial_numbers = %w(0000)
      invalid_area_numbers.include?(ssn.to_s[0,3]) || invalid_group_numbers.include?(ssn.to_s[3,2]) || invalid_serial_numbers.include?(ssn.to_s[5,4])
    end

    def is_ssn_sequential?
      # SSN should not have 6 or more sequential numbers
      sequences = []
      ssn.split('').map(&:to_i).each_cons(2) do |con_1, con_2|
        if con_2 == con_1 + 1
          sequences << [con_1, con_2]
          return true if sequences.size == 5
        else
          sequences = []
        end
      end
    end

    def is_ssn_has_same_number?
      # SSN should not have 6 or more of the same number in a row
      sequences = []
      ssn.split('').map(&:to_i).each_cons(2) do |con_1, con_2|
        if con_2 == con_1
          sequences << [con_1, con_2]
          return true if sequences.size == 5
        else
          sequences = []
        end
      end
    end
  end
end
