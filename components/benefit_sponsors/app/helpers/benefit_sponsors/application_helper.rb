module BenefitSponsors
  module ApplicationHelper
    
    def bootstrap_class_for flash_type
      #{ success: "alert-success", error: "alert-danger", alert: "alert-warning", notice: "alert-info" }[flash_type] || flash_type.to_s
      case flash_type
        when "notice"
          "alert-info"
        when "success"
          "alert-success"
        when "error"
          "alert-danger"
        when "alert"
          "alert-warning"
      end
    end

    def flash_messages(opts = {})
      flash.each do |msg_type, message|
        binding.pry
        concat(content_tag(:div, message, class: "alert #{bootstrap_class_for(msg_type)} alert-dismissible fade show") do 
          concat content_tag(:button, 'x', class: "close", data: { dismiss: 'alert' })
          concat message 
        end)
      end
      nil
    end
      
  end
end
