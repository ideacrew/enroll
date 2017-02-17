class ShopNotices::ConversionRenewalNotice < ShopNotices::RenewalGroupNotice

  def deliver
    build
    generate_pdf_notice
    append_data
    conversion_attachment
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def conversion_attachment
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'conversion_employer_attachment.pdf')]
  end

end