class RequirableFormBuilder < ActionView::Helpers::FormBuilder
  def requirable_text_field(attribute, label:, placeholder: label, required: false, **options)
    requirable_label(attribute, label, required) + text_field(attribute, options.merge(placeholder: placeholder, required: required))
  end

  def requirable_select(attribute, label:, choices:, options: {}, required: false, **html_options)
    requirable_label(attribute, label, required) + select(attribute, choices, options, html_options.merge(required: required))
  end

  private

  def requirable_label(attribute, label, required)
    label(attribute, "#{label}#{required ? " *" : ""}")
  end
end