module Subscribers
  class PolicyTerminationsSubscriber < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      ["acapi.info.events.policy.canceled", "acapi.info.events.policy.terminated"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      begin
        stringed_payload = payload.stringify_keys
        qr_uri = stringed_payload["qualifying_reason"]
        policy_instance_uri = stringed_payload["resource_instance_uri"]
        end_effective_date_str = stringed_payload["event_effective_date"]
        hbx_enrollment_id_json_list = stringed_payload["hbx_enrollment_ids"]
        is_cancel = (event_name == "acapi.info.events.policy.canceled") ? true : false
        hbx_enrollment_id_uris = JSON.parse(hbx_enrollment_id_json_list)
        hbx_enrollment_ids = hbx_enrollment_id_uris.map do |heiu|
          heiu.split("#").last
        end
        enrollments = hbx_enrollment_ids.map do |hei|
          HbxEnrollment.by_hbx_id(hei).first
        end.compact
        enrollments.each do |en|
          if is_cancel
            if en.may_cancel_coverage?
              en.cancel_coverage!
            end
          else
            if en.may_terminate_coverage?
              end_effective_date = Date.strptime(end_effective_date_str, "%Y%m%d") rescue nil
              if end_effective_date
                en.terminate_coverage!(end_effective_date)
              end
            end
          end
        end
      rescue Exception => e
        Rails.logger.error { e.to_s } unless Rails.env.test?
      end
    end
  end
end
