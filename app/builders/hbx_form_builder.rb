class HbxFormBuilder < ActionView::Helpers::FormBuilder
  def ssn_field(method, options = {})
    is_required = options.delete(:required) || false
    is_readonly = options.delete(:readonly) || false
    shared_options = {
        class: 'required floatlabel mask-ssn form-control',
        maxlength: 11,
        required: is_required,
        placeholder: (is_required ? l10n('census_employee.ssn_text') : "SOCIAL SECURITY"),
        readonly: is_readonly
    }
    if EnrollRegistry.feature_enabled?(:ssn_ui_validation)
      @template.text_field(
        @object_name,
        method,
        options.merge(
          pattern: "(?!666|000|9\\d{2})\\d{3}[\\- ]{0,1}(?!00)\\d{2}[\\- ]{0,1}(?!0{4})\\d{4}",
          oninvalid: "this.setCustomValidity('Invalid Social Security number.')",
          oninput: "this.setCustomValidity('')",
        ).merge(
          shared_options
        )
      )
    else
      @template.text_field(
        @object_name,
        method,
        options.merge(
          shared_options
        )
      )
    end
  end
end
