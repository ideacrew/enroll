module Exchanges
  module HbxProfilesHelper
    def get_person_roles(person, person_roles = [])
      person_roles << "Employee Role" if person.active_employee_roles.present?
      person_roles << "Consumer Role" if person.consumer_role.present?
      person_roles << "Hbx Staff Role" if person.hbx_staff_role.present?
      person_roles << "Assister Role" if person.assister_role.present?
      person_roles << "CSR Role" if person.csr_role.present?
      person_roles << "POC" if person.employer_staff_roles.present?
      person_roles << "Broker Agency Staff Role" if person.broker_agency_staff_roles.present?
      person_roles << "General Agency Staff Role" if person.general_agency_staff_roles.present?
      person_roles
    end

    def force_publish_warning_message
      "If you submit this application as is, the small business application may be ineligible for coverage through the Health Connector because it does not meet the eligibility reason(s) identified below

      1. Small business should have 1 - 50 full time equivalent employees
      2. Small business NOT located in Massachusetts
      2. Employer attestation documentation not provided. Select Documents on the blue menu to the left and follow the instructions to upload your documents.

      Click Cancel if you want to go back and review your application information for accuracy. If the information provided on your application is accurate, you may click Publish Anyways to proceed. If you choose to proceed and the application is determined to be ineligible, you will be notified with the reason for the eligibility determination along with what your options are to appeal this determination."
    end
  end
end
