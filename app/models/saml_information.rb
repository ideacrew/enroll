class SamlInformation

  class MissingKeyError < StandardError
    def initialize(key)
      super("Missing required key: #{key}")
    end
  end

  include Singleton

  attr_reader :config

  # TODO: I have a feeling we may be using this pattern
  #       A LOT.  Look into extracting it if we repeat.
  def initialize
    @config = YAML.load_file(File.join(Rails.root,'config', 'saml.yml'))
    ensure_configuration_values(@config)
  end

  def ensure_configuration_values(conf)
    EnrollRegistry[:saml_info_keys].setting(:saml_info_required_keys).item.each do |k|
      if @config[k].blank?
        raise MissingKeyError.new(k)
      end
    end
  end

  def self.define_key(key)
    define_method(key.to_sym) do
      config[key.to_s]
    end
    self.instance_eval(<<-RUBYCODE)
      def self.#{key.to_s}
        self.instance.#{key.to_s}
      end
    RUBYCODE
  end

  EnrollRegistry[:saml_info_keys].setting(:saml_info_required_keys).item.each do |k|
    define_key k
  end

end
