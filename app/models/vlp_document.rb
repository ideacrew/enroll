class VlpDocument < Document

  NATURALIZATION_DOCUMENT_TYPES = ["Certificate of Citizenship", "Naturalization Certificate"]

  VLP_DOCUMENT_IDENTIFICATION_KINDS = [
      "Alien Number",
      "I-94 Number",
      "Visa Number",
      "Passport Number",
      "SEVIS ID",
      "Naturalization Number",
      "Receipt Number",
      "Citizenship Number",
      "Card Number"
    ]

  VLP_DOCUMENT_KINDS = [
      "I-327 (Reentry Permit)",
      "I-551 (Permanent Resident Card)",
      "I-571 (Refugee Travel Document)",
      "I-766 (Employment Authorization Card)",
      "Certificate of Citizenship",
      "Naturalization Certificate",
      "Machine Readable Immigrant Visa (with Temporary I-551 Language)",
      "Temporary I-551 Stamp (on passport or I-94)",
      "I-94 (Arrival/Departure Record)",
      "I-94 (Arrival/Departure Record) in Unexpired Foreign Passport",
      "Unexpired Foreign Passport",
      "I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)",
      "DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)",
      "Other (With Alien Number)",
      "Other (With I-94 Number)"
    ]

  field :alien_number, type: String
  field :i94_number, type: String
  field :visa_number, type: String
  field :passport_number, type: String
  field :sevis_id, type: String
  field :naturalization_number, type: String
  field :receipt_number, type: String
  field :citizenship_number, type: String
  field :card_number, type: String

  # date of expiration of the document. e.g. passport / documentexpiration date
  field :expiration_date, type: Date

  # country which issued the document. e.g. passport issuing country
  field :issuing_country, type: String

  field :vlp_document_kind, type: String

  validates :vlp_document_kind,
        inclusion: { in: VLP_DOCUMENT_KINDS, message: "%{value} is not a valid vlp document kind" },
        allow_blank: false

  validates :alien_number, length: { is: 9 }
  validates :citizenship_number, length: { within: 7..9 }
  validates :i94_number, length: { is: 11 }
  validates :naturalization_number, length: { within: 7..12 }
  validates :passport_number, length: { within: 6..12 }
  validates :sevis_id, length: { is: 11 } #first char is N
  validates :visa_number, length: { is: 8 }
  validates :receipt_number, length: { is: 13} #first 3 alpha, remaining 10 string

end
