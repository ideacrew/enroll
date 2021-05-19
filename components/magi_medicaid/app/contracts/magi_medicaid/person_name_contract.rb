# frozen_string_literal: true

module MagiMedicaid
  class PersonNameContract < Dry::Validation::Contract


    params do
      optional(:name_pfx).maybe(:string)
      required(:first_name).maybe(:string)
      optional(:middle_name).maybe(:string)
      required(:last_name).maybe(:string)
      optional(:name_sfx).maybe(:string)
    end
  end
end