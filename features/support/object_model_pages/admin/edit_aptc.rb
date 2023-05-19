# frozen_string_literal: true

#admin/families tab/ edit aptc action
class EditAptc

  def self.csr_pct_as_integer
    '[data-cuke="csr_pct"]'
  end

  def self.edit_aptc_csr_action
    '.edit-aptc-csr-enabled'
  end

  def self.aptc_slider
    '[data-cuke="aptc_slider"]'
  end

  def self.applied_aptc_field
    '[data-cuke="applied_aptc_field"]'
  end
end
