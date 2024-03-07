FactoryBot.define do
  factory :consumer_role do
    association :person
    sequence(:ssn) do |n|
      ssn = ''
      loop do
        ssn_number = SecureRandom.random_number(1_000_000_000)
        ssn = "7#{ssn_number.to_s[2..3]}#{ssn_number.to_s[4]}#{n + 1}#{ssn_number.to_s[5..7]}#{n + 1}"
        break if ssn.match?(/^(?!666|000|9\d{2})\d{3}[- ]{0,1}(?!00)\d{2}[- ]{0,1}(?!0{4})\d{4}$/)
      end

      ssn
    end
    dob { "01/01/1980" }
    gender { 'male' }
    is_state_resident { 'yes' }
    citizen_status { 'us_citizen' }
    is_applicant { 'yes' }
    active_vlp_document_id { vlp_document.id }
    vlp_documents { [vlp_document] }
    ridp_documents {[FactoryBot.build(:ridp_document)]}
    bookmark_url { nil }
    is_applying_coverage { true }

    transient do
      vlp_document { FactoryBot.build(:vlp_document) }
    end
  end

  factory(:consumer_role_person, {class: ::Person}) do
    first_name { Forgery(:name).first_name }
    last_name { Forgery(:name).first_name }
    gender { Forgery(:personal).gender }
    sequence(:ssn, 222222222)
    dob { Date.new(1980, 1, 1) }
  end


  factory(:consumer_role_object, {class: ::ConsumerRole}) do
    is_applicant { true }
    person { FactoryBot.create(:consumer_role_person) }
  end
end
