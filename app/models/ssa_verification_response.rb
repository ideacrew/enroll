  class SsaVerificationResponse 
    include Mongoid::Document
    include Mongoid::Timestamps

    field :response_code,  type: String
    field :response_text, type: String
    field :ssn_verification_failed, type: String
    field :ssn_verified, type: String
    field :death_confirmation, type: String
    field :citizenship_verified, type: String
    field :incarcerated, type: String
    
    field :ssn,type: String
    field :sex,type: String
    field :birth_date,type: Date
    field :is_state_resident, type: Boolean
    field :citizen_status,type: String
    field :marital_status,type: String
    field :death_date,type: String
    field :race,type: String
    field :ethnicity,type: String

    field :person_id,type: String
    field :first_name,type: String
    field :last_name,type: String
    field :name_pfx,type: String
    field :name_sfx,type: String
    field :middle_name,type: String
    field :full_name,type: String

    embeds_many :individual_address, class_name: "::Address" 
    embeds_many :individual_phone, class_name: "::Phone" 
    embeds_many :individual_email, class_name: "::Email" 

    
    embedded_in :lawful_presence_determination

  end
