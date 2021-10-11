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