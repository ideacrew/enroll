class ShopBrokerAgencyNotices::BrokerAgencyHiredNotice < ShopBrokerAgencyNotice
 def deliver
   build
   append_data
   generate_pdf_notice
   attach_envelope
   non_discrimination_attachment
   upload_and_send_secure_message
   send_generic_notice_alert
  end

  def append_data
    notice.assignment_date = employer_profile.broker_agency_accounts.detect{|br| br.is_active == true}.start_on
  end
end