unless Object.const_defined?(:SPONSORED_BENEFIT_ROOT)
  SPONSORED_BENEFIT_ROOT = File.dirname(File.dirname(__FILE__))
  Dir[File.join(SPONSORED_BENEFIT_ROOT, 'spec', 'factories', '*.rb')].each do |file|
    require(file)
  end
end
