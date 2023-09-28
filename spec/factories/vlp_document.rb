FactoryBot.define do
  factory :vlp_document do
    alien_number { "123456789" }
    receipt_number { "abc4567890123" }
    expiration_date { Date.today }
    issuing_country { "USA" }
    identifier { "identifier" }
    country_of_citizenship { "Ukraine" }
    passport_number { "123456" }
    subject { VlpDocument::VLP_DOCUMENT_KINDS[0] } #I-327 (Reentry Permit) and validates on :alien_number

    trait :other_with_i94_number do
      alien_number { '' }
      visa_number { '' }
      naturalization_number { '' }
      receipt_number { '' }
      citizenship_number { '' }
      issuing_country { '' }
      card_number { '' }
      type { "text" }
      source { "enroll_system" }
      language { "en" }
      status { "not submitted" }
      subject { "Other (With I-94 Number)" }
      passport_number { "" }
      sevis_id { "" }
      expiration_date { nil }
      description { "test" }
      i94_number { "28798256761" }
      country_of_citizenship { "" }
    end

    trait :i766 do
      alien_number { '123456789' }
      visa_number { '' }
      naturalization_number { '' }
      receipt_number { '' }
      citizenship_number { '' }
      issuing_country { '' }
      card_number { '9876543211234' }
      type { 'text' }
      source { 'enroll_system' }
      language { 'en' }
      status { 'not submitted' }
      subject { 'I-766 (Employment Authorization Card)' }
      passport_number { '' }
      sevis_id { '' }
      expiration_date { nil }
      description { '' }
      i94_number { '' }
      country_of_citizenship { '' }
    end
  end
end
