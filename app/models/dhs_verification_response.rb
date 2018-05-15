class DhsVerificationResponse 
    include Mongoid::Document
    include Mongoid::Timestamps

    field :response_code,  type: String
    field :response_text, type: String 
    field :case_number,  type: String 
    
    field :case_number,  type: String 
    field :response_code,  type: String
    field :response_code,  type: String

    field :document_DS2019, type: String
    field :document_I20, type: String
    field :document_I327, type: String
    field :document_I551, type: String
    field :document_I571, type: String
    field :document_I766,type: String
    field :document_I94,type: String
    field :document_cert_of_citizenship,type: String
    field :document_cert_of_naturalization, type: String
    field :cert_of_naturalization_admitted_to_date,type: String
    field :cert_of_naturalization_admitted_to_text,type: String
    field :cert_of_naturalization_case_number,type: String
    field :cert_of_naturalization_coa_code,type: String
    field :cert_of_naturalization_country_birth_code,type: String
    field :cert_of_naturalization_country_citizen_code,type: String
    field :cert_of_naturalization_eads_expire_date,type: String
    field :cert_of_naturalization_elig_statement_code,type: String
    field :cert_of_naturalization_elig_statement_txt,type: String
    field :cert_of_naturalization_entry_date,type: String
    field :cert_of_naturalization_grant_date,type: String
    field :cert_of_naturalization_grant_date_reason_code,type: String
    field :cert_of_naturalization_iav_type_code,type: String
    field :cert_of_naturalization_iav_type_text,type: String
    field :cert_of_naturalization_response_code,type: String
    field :cert_of_naturalization_response_description_text,type: String
    field :cert_of_naturalization_tds_response_description_text,type: String
    #passport fields
    field :passport_admitted_to_date,type: String
    field :passport_admitted_to_text,type: String
    field :passport_case_number,type: String
    field :passport_coa_code,type: String
    field :passport_country_birth_code,type: String
    field :passport_country_citizen_code,type: String
    field :passport_eads_expire_date,type: String
    field :passport_elig_statement_code,type: String
    field :passport_elig_statement_txt,type: String
    field :passport_entry_date,type: String
    field :passport_grant_date,type: String
    field :passport_grant_date_reason_code,type: String
    field :passport_iav_type_code,type: String
    field :passport_iav_type_text,type: String
    field :passport_response_code,type: String
    field :passport_response_description_text,type: String
    field :passport_tds_response_description_text,type: String
    field :document_foreign_passport_I94,type: String
    field :document_mac_read_I551,type: String
    field :document_other_case_1,type: String
    field :document_other_case_2,type: String
    field :document_temp_I551,type: String
    field :document_other_case_1,type: String
    field :document_other_case_2,type: String 
    field :employment_authorized, type: String
    field :legal_status,type: String
    field :response_code,type: String
    field :lawful_presence_indeterminate, type: String 

    
    embedded_in :lawful_presence_determination

  end