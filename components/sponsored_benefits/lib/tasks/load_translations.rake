namespace :seed do
  desc "Load the translation data"
  task :translation => :environment do
    Translation.delete_all
    en =  YAML::load(File.read(File.open("config/locales/view.en.yml",'r')))
    es =  YAML::load(File.read(File.open("config/locales/view.es.yml",'r')))
    puts "Loading en translation...."
    en["en"]["button"].keys.each do |key|
      value = en["en"]["button"][key]
      Translation.create(key: "en.button.#{key}", value: "\"#{value}\"")
    end
    en["en"]["welcome"].keys.each do |key|
      value = en["en"]["welcome"][key]
      Translation.create(key: "en.welcome.#{key}", value:  "\"#{value}\"")
    end
    puts "Loading es translation...."
    es["es"]["button"].keys.each do |key|
      value = es["es"]["button"][key]
      Translation.create(key: "es.button.#{key}", value:  "\"#{value}\"")
    end
    es["es"]["welcome"].keys.each do |key|
      value = es["es"]["welcome"][key]
      Translation.create(key: "es.welcome.#{key}", value:  "\"#{value}\"")
    end
    puts "Loaded #{Translation.all.count} translations."
  end
end
