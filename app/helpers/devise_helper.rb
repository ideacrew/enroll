module DeviseHelper
  def devise_error_messages!
    return "" if resource.errors.empty?

    resource.errors.messages[:username] = resource.errors.messages.delete :oim_id

    messages = resource.errors.full_messages.map { |msg| content_tag(:li, msg) }.join
    sentence = I18n.t("errors.messages.not_saved",
                      count: resource.errors.count,
                      resource: resource.class.model_name.human.downcase)

    top_div = '<div class="alert alert-error module registration-rules" role="alert">'.html_safe
    
    if resource.errors.messages.keys.include?(:password)
      password_div = '
        <div class="text-center">
          <strong>
            Password Requirements
          </strong>
        </div>'.html_safe
    else
      password_div = ''
    end
    error_messages_div = 
      "
      <br/>
      <strong>#{sentence}</strong>
      <ul>#{messages}</ul>
    </div>".html_safe
    top_div + password_div + error_messages_div
  end
end
