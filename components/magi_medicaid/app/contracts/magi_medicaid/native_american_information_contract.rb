# frozen_string_literal: true

module MagiMedicaid
  # Native American validation contract.
  class NativeAmericanInformationContract < Dry::Validation::Contract

    params do
      optional(:indian_tribe_member).maybe(:bool)
      optional(:tribal_id).maybe(:string)
    end

    # rule(:indian_tribe_member) do
    #   if values[:is_applying_coverage]
    #     key.failure(text: "Indian tribe member question must be answered") if values[:indian_tribe_member].to_s.blank?
    #   end
    # end
    # yet another thing to fix
  end
end