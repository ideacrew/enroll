module Config::ContactCenterConcern

  def contact_center_phone_number
    Settings.contact_center.phone_number
  end

  def contact_center_name
    Settings.contact_center.name
  end

  def contact_center_alt_name
    Settings.contact_center.alt_name
  end

  def contact_center_tty_number
    Settings.contact_center.tty_number
  end

  def contact_center_alt_phone_number
    Settings.contact_center.alt_phone_number
  end

  def contact_center_email_address
    Settings.contact_center.email_address
  end
end
