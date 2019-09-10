# frozen_string_literal: true

module Products
  module Services
    class BaseService

      NO_CHARGE = "No Charge"
      NO_CHARGE_RESULTS = [NO_CHARGE, "Not Applicable"].freeze
      DEVICES = ["Durable Medical Equipment", "Prosthetic Devices"].freeze

      DRUG_DEDUCTIBLE_OPTIONS = [
        "Separate Drug Deductible",
        "Generic Drugs",
        "Preferred Brand Drugs",
        "Non-Preferred Brand Drugs",
        "Specialty Drugs"
      ].freeze

    end
  end
end
