module Subscribers
  class DefaultGaChanged < ::Acapi::Subscription
    def self.subscription_details
      ["acapi.info.events.broker.default_ga_changed"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      stringed_key_payload = payload.stringify_keys
      hbx_id = stringed_key_payload["broker_id"]
      pre_default_ga_id = BSON::ObjectId.from_string(stringed_key_payload["pre_default_ga_id"]) rescue ""
      person = Person.by_hbx_id(hbx_id).last
      broker_agency_profile = person.broker_role.broker_agency_profile rescue nil
      if broker_agency_profile.present?
        if broker_agency_profile.default_general_agency_profile.present?
          #change
          plan_design_organizations = SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_owner(broker_agency_profile.id)
          plan_design_organizations.each do |pdo|
            if pdo.active_general_agency_account.blank?
              service.create_general_agency_account(pdo.id, person.broker_role.id, TimeKeeper.datetime_of_record, broker_agency_profile.default_general_agency_profile_id, broker_agency_profile.id)
              send_general_agency_assign_msg(broker_agency_profile, broker_agency_profile.default_general_agency_profile, pdo.employer_profile, 'Hire')
            end
          end
        else
          #clear
          return if pre_default_ga_id.blank?
          plan_design_organizations = SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_owner(broker_agency_profile.id).find_by_general_agency(pre_default_ga_id)
          plan_design_organizations.each do |pdo|
            general_agency_profile = pdo.active_general_agency_account && pdo.active_general_agency_account.general_agency_profile
            if general_agency_profile && general_agency_profile.id.to_s == pre_default_ga_id.to_s
              send_general_agency_assign_msg(broker_agency_profile, general_agency_profile, pdo.employer_profile, 'Terminate')
              service.fire_general_agency([pdo.id])
            end
          end
        end
      end
    rescue Exception => e
      log("GA_ERROR: Unable to set default ga for #{e.try(:message)}", {:severity => "error"})
    end

    def service
      return @service if defined? @service
      @service = SponsoredBenefits::Services::GeneralAgencyManager.new(nil)
    end

    def send_general_agency_assign_msg(broker_agency_profile, general_agency, employer_profile, status)
      subject = "You are associated to #{employer_profile.legal_name}- #{general_agency.legal_name} (#{status})"
      body = "<br><p>Associated details<br>General Agency : #{general_agency.legal_name}<br>Employer : #{employer_profile.legal_name}<br>Status : #{status}</p>"
      secure_message(broker_agency_profile, general_agency, subject, body)
      secure_message(broker_agency_profile, employer_profile, subject, body)
    end

    def secure_message(from_provider, to_provider, subject, body)
      message_params = {
        sender_id: from_provider.id,
        parent_message_id: to_provider.id,
        from: from_provider.legal_name,
        to: to_provider.legal_name,
        subject: subject,
        body: body
      }

      create_secure_message(message_params, to_provider, :inbox)
      create_secure_message(message_params, from_provider, :sent)
    end

    def create_secure_message(message_params, inbox_provider, folder)
      message = Message.new(message_params)
      message.folder =  Message::FOLDER_TYPES[folder]
      msg_box = inbox_provider.inbox
      msg_box.post_message(message)
      msg_box.save
    end
  end
end
