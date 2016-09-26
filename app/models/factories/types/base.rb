module Factories
  module Types
    class Base

      attr_reader :transcript, :fields_to_ignore

      def initialize
        @transcript = transcript_template
      end

      def match
        raise StandardError "Implement this method in child class"
      end

      def build
        raise StandardError "Implement this method in child class"
      end

      def compare
        differences     = HashWithIndifferentAccess.new
        base_record     = @transcript[:source]
        compare_record  = @transcript[:other]
        # all_keys        = (base_record.keys + compare_record.keys).uniq!

        all_keys = base_record.attribute_names.reject{|attr| @fields_to_ignore.include?(attr)}

        all_keys.each do |k|
          next if base_record[k].blank? && compare_record[k].blank?

          if base_record[k].blank?
            differences[:add] ||= {}
            differences[:add][k] = compare_record[k]
          elsif compare_record[k].blank?
            differences[:remove] ||= {}
            differences[:remove][k] = base_record[k]
          elsif base_record[k].is_a?(Array) && compare_record[k].is_a?(Array)
            differences[:array] ||= {}
            old_values = base_record[k] - compare_record[k]
            new_values = compare_record[k] - base_record[k]
            differences[:array][k] = { add: new_values, remove: old_values }.delete_if { |_, vv| vv.blank? }
            differences[:array][k].blank? ? differences = {} : differences[:array]
          else
            if base_record[k] != compare_record[k]
              differences[:update] ||= {}
              differences[:update][k] = compare_record[k]
            end
          end
        end

        @transcript[:compare] = differences
      end

      def validate_import
        @transcript[:source].is_valid?
        @transcript[:other].is_valid?
        @transcript[:source_errors] = @transcript[:source].errors
        @transcript[:other_errors] = @transcript[:other].errors
      end

      # Return model instance using the transcript hash table values
      def to_model
      end

      def copy_properties(from, to, properties)
        properties.each { |property| copy_property(from, to, property) }
      end

      def copy_property(from, to, property)
        to.send("#{property}=", from.send(property))
      end

      # Hash table for managing transcript factory data
      def transcript_template
        {
          # Local data set values
          source:         HashWithIndifferentAccess.new,
          # External data set values 
          other:          HashWithIndifferentAccess.new,
          # Result of comparing values of the "source" and "other" content
          compare:        HashWithIndifferentAccess.new,
          # Functional errors in the "source" data set
          source_errors:  HashWithIndifferentAccess.new,
          # Functional errors in the "other" data set
          other_errors:   HashWithIndifferentAccess.new,
          # "source" data set was generated from the "other" data set values?
          source_is_new:  true,
        }
      end
    end
  end
end
