class RequirableFieldFormBuilder < ActionView::Helpers::FormBuilder
  def text_field(attribute, placeholder, required: false, options: {})
    super(attribute, options.merge(placeholder: "#{placeholder}#{required ? " *" : ""}", required: required))
  end
end
