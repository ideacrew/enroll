# frozen_string_literal: true

# Used for changing translations for testing
# please set an "after" block to change it back after, like so:
# after do
#   state_name = EnrollRegistry[:enroll_app].settings(:site_key).item.to_s.downcase
#   change_target_translation_text("en.user_mailer.account_transfer_success_notification.full_text", state_name, "user_mailer")
# end
module TranslationSpecHelper
  def change_target_translation_text(translation_key, state_name, filename)
    seedfile_location = "db/seedfiles/translations/en/#{state_name}/#{filename}.rb"
    require "#{Rails.root}/#{seedfile_location}"
    # Save the constant from the file
    "#{filename.upcase}_TRANSLATIONS".constantize.each do |key, value|
      Translation.where(key: key).first_or_create.update_attributes!(value: "\"#{value}\"") if key == translation_key
    end
  end
end