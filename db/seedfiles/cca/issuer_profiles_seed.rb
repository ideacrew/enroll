glob_pattern = File.join(File.dirname(__FILE__), "fixtures", "issuer_profile_*.yaml")

Dir.glob(glob_pattern).each do |f_name|
  loaded_class = ::BenefitSponsors::Organizations::ExemptOrganization
  yaml_str = File.read(f_name)
  data = YAML.load(yaml_str)
  data.save!
end
