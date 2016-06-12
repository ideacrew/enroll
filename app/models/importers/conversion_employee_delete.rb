module Importers
  class ConversionEmployeeDelete
    include ActiveModel::Validations
    include ActiveModel::Model

    include ::Etl::ValueParsers

    attr_converter :subscriber_ssn, :fein, :as => :optimistic_ssn
    attr_converter :subscriber_gender, :as => :gender

    attr_reader :warnings, :subscriber_dob, :hire_date, :subscriber_zip

    attr_accessor :action,
      :employer_name,
      :benefit_begin_date,
      :subscriber_name_first,
      :subscriber_name_middle,
      :subscriber_name_last,
      :subscriber_email,
      :subscriber_phone,
      :subscriber_address_1,
      :subscriber_address_2,
      :subscriber_city,
      :subscriber_state,
      :default_hire_date

      (1..8).to_a.each do |num|
        attr_converter "dep_#{num}_ssn".to_sym, :as => :optimistic_ssn
        attr_converter "dep_#{num}_gender".to_sym, :as => :gender
      end
      (1..8).to_a.each do |num|
        attr_reader "dep_#{num}_dob".to_sym,
          "dep_#{num}_relationship".to_sym,
          "dep_#{num}_zip".to_sym
      end
      (1..8).to_a.each do |num|
        attr_accessor "dep_#{num}_name_first".to_sym,
          "dep_#{num}_name_middle".to_sym,
          "dep_#{num}_name_last".to_sym,
          "dep_#{num}_email".to_sym,
          "dep_#{num}_phone".to_sym,
          "dep_#{num}_address_1".to_sym,
          "dep_#{num}_address_2".to_sym,
          "dep_#{num}_city".to_sym,
          "dep_#{num}_state".to_sym
      end

      validates_length_of :fein, is: 9

      validate :prohibit_delete

      RELATIONSHIP_MAP = {
        "spouse" => "spouse",
        "domestic partner" => "domestic_partner",
        "child under 26" => "child_under_26",
        "child over 26" => "child_26_and_over",
        "disabled child under 26" => "disabled_child_26_and_over"
      }

      def initialize(opts = {})
        super(opts)
        @warnings = ActiveModel::Errors.new(self)
      end

      def hire_date=(val)
        @hire_date = val.blank? ? nil : (Date.strptime(val, "%m/%d/%Y") rescue nil)
      end

      def subscriber_dob=(val)
        @subscriber_dob = val.blank? ? nil : (Date.strptime(val, "%m/%d/%Y") rescue nil)
      end

      def subscriber_zip=(val)
        if val.blank?
          @subscriber_zip = nil
          return val
        else
          if val.strip.length == 9 
            @subscriber_zip = val[0..4]
          else
            @subscriber_zip = val.strip.rjust(5, "0")
          end 
        end
      end

      (1..8).to_a.each do |num|
        class_eval(<<-RUBYCODE)
      def dep_#{num}_zip=(val)
        if val.blank?
          @dep_#{num}_zip = nil
          return val
        else
          if val.strip.length == 9 
            @dep_#{num}_zip = val[0..4]
          else
            @dep_#{num}_zip = val.strip.rjust(5, "0")
          end 
        end
      end

          def dep_#{num}_relationship=(val)
            dep_rel = Maybe.new(val).strip.downcase.extract_value
            @dep_#{num}_relationship = RELATIONSHIP_MAP[dep_rel]
          end

          def dep_#{num}_dob=(val)
            @dep_#{num}_dob = val.blank? ? nil : (Date.strptime(val, ("%m/%d/%Y")) rescue nil)
          end
        RUBYCODE
      end

      def prohibit_delete
        errors.add(:action, "delete instructions are ignored")
      end

      def save
        valid?
      end
  end
end
