module FamilySugarCrmConcern
  extend ActiveSupport::Concern

  included do
    after_save :trigger_crm_family_update_publish
  end

  def trigger_crm_family_update_publish
    params = self.attributes
    ::Operations::Families::SugarCrm::UpdateFamily.new.call(params) unless Rails.env.test?
  end
end
