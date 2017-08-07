module PdfTemplates
  class BasicIndividual
    include Virtus.model

    attribute :first_name, String
    attribute :last_name, String
    attribute :age, String
  end
end
