Notifier::Engine.class_eval do
  paths["app/helpers"] << File.join(File.dirname(__FILE__), '../../../../', 'app/helpers') unless Rails.env.test?
end