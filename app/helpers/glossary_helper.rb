# frozen_string_literal: true

module GlossaryHelper
  def support_texts(key)
    @support_texts ||= {}
    @support_texts[key] ||= ERB.new(YAML.load_file("app/views/shared/support_text_household.yml")[key]).result
  end
end
