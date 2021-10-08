# frozen_string_literal: true

module LanguageHelper
  ALL_LANGUAGES = [
    ["Afrikaans", "af"], ["Arabic", "ar"], ["Bengali", "bn"],
    ["Tibetan", "bo"], ["Bulgarian", "bg"], ["Catalan", "ca"],
    ["Czech", "cs"], ["Welsh", "cy"], ["Danish", "da"],
    ["German", "de"], ["Greek", "el"], ["English", "en"],
    ["Estonian", "et"], ["Basque", "eu"], ["Persian", "fa"],
    ["Fijian", "fj"], ["Finnish", "fi"], ["French", "fr"], ["Irish", "ga"],
    ["Gujarati", "gu"], ["Hebrew", "he"], ["Hindi", "hi"], ["Croatian", "hr"],
    ["Hungarian", "hu"], ["Armenian", "hy"], ["Indonesian", "id"], ["Icelandic", "is"],
    ["Italian", "it"], ["Japanese", "ja"], ["Georgian", "ka"], ["Khmer", "km"],
    ["Korean", "ko"], ["Latin", "la"], ["Lingala", "ln"], ["Latvian", "lv"],
    ["Lithuanian", "lt"], ["Malayalam", "ml"], ["Marathi", "mr"], ["Macedonian", "mk"],
    ["Maltese", "mt"], ["Mongolian", "mn"], ["Maori", "mi"], ["Malay", "ms"],
    ["Nepali", "ne"], ["Dutch", "nl"], ["Norwegian", "no"], ["Panjabi", "pa"],
    ["Polish", "pl"], ["Portuguese", "pt"], ["Quechua", "qu"], ["Romanian", "ro"],
    ["Kirundi", "rn"], ["Russian", "ru"], ["Slovak", "sk"], ["Slovenian", "sl"],
    ["Samoan", "sm"], ["Somali", "so"], ["Spanish", "es"], ["Albanian", "sq"],
    ["Serbian", "sr"], ["Swahili", "sw"], ["Swedish", "sv"], ["Tamil", "ta"],
    ["Tatar", "tt"], ["Telugu", "te"], ["Thai", "th"], ["Tagalog", "tl"],
    ["Tonga (Tonga Islands)", "to"], ["Turkish", "tr"], ["Ukrainian", "uk"], 
    ["Urdu", "ur"], ["Uzbek", "uz"], ["Vietnamese", "vi"], ["Xhosa", "xh"], ["Chinese", "zh"]
  ].freeze

  def language_options
    ALL_LANGUAGES
  end
end
