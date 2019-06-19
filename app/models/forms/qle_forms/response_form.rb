module Forms
  module QleForms
    class ResponseForm
      include Virtus.model
      extend ActiveModel::Naming
      include ActiveModel::Conversion
      include ActiveModel::Model
      include ActiveModel::Validations

      attribute :name, String
      attribute :operator, String
      attribute :value, Date
      attribute :value_2, Date
      attribute :result, Symbol
    end
  end
end
