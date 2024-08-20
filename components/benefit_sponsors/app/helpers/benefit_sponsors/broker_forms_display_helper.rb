# frozen_string_literal: true

module BenefitSponsors
  # helper to display possible languages for broker
  # made a new helper to order the languages without doing too much in the view
  module BrokerFormsDisplayHelper
    ALL_LANGUAGES = [
      ["English", "en"], ["Chinese", "zh"], ["Afrikaans", "af"], ["Albanian", "sq"], ["Arabic", "ar"], ["Armenian", "hy"],
      ["Spanish", "es"], ["Japanese", "ja"], ["Basque", "eu"], ["Bengali", "bn"], ["Bulgarian", "bg"], ["Catalan", "ca"],
      ["French", "fr"], ["Korean", "ko"], ["Croatian", "hr"], ["Czech", "cs"], ["Danish", "da"], ["Dutch", "nl"],
      ["German", "de"], ["Vietnamese", "vi"], ["Estonian", "et"], ["Fijian", "fj"], ["Finnish", "fi"], ["Georgian", "ka"],
      ["Greek", "el"], ["Gujarati", "gu"], ["Hebrew", "he"], ["Hindi", "hi"], ["Hungarian", "hu"], ["Icelandic", "is"],
      ["Indonesian", "id"], ["Irish", "ga"], ["Italian", "it"], ["Khmer", "km"], ["Kirundi", "rn"], ["Latvian", "lv"],
      ["Lingala", "ln"], ["Lithuanian", "lt"], ["Macedonian", "mk"], ["Malay", "ms"], ["Malayalam", "ml"], ["Maltese", "mt"],
      ["Marathi", "mr"], ["Mongolian", "mn"], ["Nepali", "ne"], ["Norwegian", "no"], ["Punjabi", "pa"], ["Persian", "fa"],
      ["Polish", "pl"], ["Portuguese", "pt"], ["Quechua", "qu"], ["Romanian", "ro"], ["Russian", "ru"], ["Samoan", "sm"],
      ["Serbian", "sr"], ["Slovak", "sk"], ["Slovenian", "sl"], ["Somali", "so"], ["Swahili", "sw"], ["Swedish", "sv"],
      ["Tagalog", "tl"], ["Tamil", "ta"], ["Tatar", "tt"], ["Telugu", "te"], ["Thai", "th"], ["Tibetan", "bo"],
      ["Tongan", "to"], ["Turkish", "tr"], ["Ukrainian", "uk"], ["Urdu", "ur"], ["Uzbek", "uz"], ["Welsh", "cy"],
      ["Xhosa", "xh"]
    ].freeze

    def display_languages
      ALL_LANGUAGES.each_slice(6).to_a
    end

    def determine_phone_number(object)
      if object&.full_number_without_extension&.present?
        object&.full_number_without_extension
      elsif object&.area_code&.present? && object&.number&.present?
        "#{object.area_code}#{object.number}"
      else
        ''
      end
    end

    def address_is_primary?(form)
      form.object.is_primary?
    end
  end
end