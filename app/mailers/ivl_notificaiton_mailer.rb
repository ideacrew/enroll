class IvlNotificationMailer < ApplicationMailer

  def lawful_presence_verified(user)
    notice = Notice.new(user.email, {:notice_data => {:user => user}, :template => "notices/sample_notice.html.erb"})
    attachments["notice.pdf"] = notice.send_paper_notice
    _link = link_to("click here", :controller => "ivl_notifications").to_html
    
    mail({to: user.email, subject: "DCHealthLink Notification"}) do |format|
      format.html { render "ivl_notification", :locals => { :user => user, :link => _link}}
    end
  end

  def lawful_presence_unverified(user)
    notice = Notice.new(user.email, {:notice_data => {:user => user}, :template => "notices/sample_notice.html.erb"})
    attachments["notice.pdf"] = notice.send_paper_notice
    _link = link_to("click here", :controller => "ivl_notifications").to_html
    mail({to: user.email, subject: "DCHealthLink Notification"}) do |format|
      format.html { render "ivl_notification", :locals => { :user => user, :link => _link}}
    end
  end

  def lawfully_ineligible(user)
    notice = Notice.new(user.email, {:notice_data => {:user => user}, :template => "notices/sample_notice.html.erb"})
    attachments["notice.pdf"] = notice.send_paper_notice
    _link = link_to("click here", :controller => "ivl_notifications").to_html
    mail({to: user.email, subject: "DCHealthLink Notification"}) do |format|
      format.html { render "ivl_notification", :locals => { :user => user, :link => _link}}
    end
  end
  
end 
