module Validations
  class DateRangeValidator < ActiveModel::Validator

    unless defined?(Validations::DateRangeValidator::DATA_TYPES)
      Validations::DateRangeValidator::DATA_TYPES = [Date, Time]
    end

    def validate(record)
      record.attributes.keys.each do |key|
        if DATA_TYPES.include? record.attributes[key].class
          record.errors[key] << 'date cannot be more than 110 years ago' if record.attributes[key] < TimeKeeper.date_of_record - 110.years
        end
      end
    end
  end
end
