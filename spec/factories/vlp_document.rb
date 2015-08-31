FactoryGirl.define do
  factory :vlp_document do
    alien_number "123456789"
    receipt_number "abc4567890123"
    expiration_date Date.today
    issuing_country "USA"
    passport_number "123456"
    subject VlpDocument::VLP_DOCUMENT_KINDS[Random.rand(VlpDocument::VLP_DOCUMENT_KINDS.length)]
  end
end
