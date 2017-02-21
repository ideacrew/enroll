class ShopNotices::ConversionRenewalNotice < ShopNotice

  def deliver
    build
    generate_pdf_notice
    append_data
    conversion_attachment
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def append_data
    renewing_plan_year = employer_profile.plan_years.where(:aasm_state => "renewing_draft").first
    notice.plan_year = PdfTemplates::PlanYear.new({
          :start_on => renewing_plan_year.start_on,
          :carrier_name => renewing_plan_year.benefit_groups.first.reference_plan.carrier_profile.legal_name
        })
  end

  def conversion_attachment
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'conversion_employer_attachment.pdf')]
  end

end