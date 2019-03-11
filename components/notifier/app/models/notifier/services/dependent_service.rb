module Notifier
  #Dependent service for UQHPAQHP of Projected Renewal Eligibility Notice
  class Services::DependentService

    attr_accessor :is_uqhp_notice, :payload_member, :age, :is_aqhp_eligible
    attr_accessor :person, :is_toatally_ineligible, :is_uqhp_eligible
    attr_accessor :first_name, :last_name

    def initialize(is_uqhp_notice, member)
      @is_uqhp_notice = is_uqhp_notice
      @payload_member = member
      extract_person_details
      toatally_ineligible?
      uqhp_eligible?
      aqhp_eligible?
    end

    private

    def extract_person_details
      @person = Person.by_hbx_id(payload_member['person_hbx_id']).first
      calculate_age
      f_name
      l_name
    end

    def f_name
      @first_name =
        if is_uqhp_notice
          person.first_name
        else
          payload_member['first_name']
        end
    end

    def l_name
      @last_name =
        if is_uqhp_notice
          person.last_name
        else
          payload_member['last_name']
        end
    end

    def calculate_age
      @age =
      if is_uqhp_notice
        person.age_on(TimeKeeper.date_of_record).presence || nil
      else
        Date.current.year - Date.parse(payload_member['dob']).year
      end
    end

    def aqhp_eligible?
      @is_aqhp_eligible =
        if is_uqhp_notice
          false
        else
          payload_member['aqhp_eligible'].casecmp('YES').zero?
        end
    end

    def toatally_ineligible?
      @is_toatally_ineligible =
        if is_uqhp_notice
          false
        else
          payload_member['totally_inelig'].casecmp('YES').zero?
        end
    end

    def uqhp_eligible?
      @is_uqhp_eligible =
        if is_uqhp_notice
          true
        else
          payload_member['uqhp_eligible'].casecmp('YES').zero?
        end
    end


  end
end
