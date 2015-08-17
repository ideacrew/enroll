class IvlNotificationMailer < ApplicationMailer
  include ActionView::Helpers::UrlHelper
   # helper ActionView::Helpers::UrlHelper
   
  def lawful_presence_verified(user)
    notice = Notice.new(user.email, {:notice_data => {:user => user}, :template => "notices/9cindividual.html.erb"})    
    attachments["notice.pdf"] = File.read(notice.send_paper_notice)
    _link = link_to("click here", :controller => "ivl_notifications").to_html
    mail({to: user.email.address, subject: "DCHealthLink Notification"}) do |format|
      format.html { render "ivl_notification", :locals => { :user => user, :link => _link}}
    end
  end

  def lawful_presence_unverified(user)
    notice = Notice.new(user.email, {:notice_data => {:user => user}, :template => "notices/9cindividual.html.erb"})
    attachments["notice.pdf"] = File.read(notice.send_paper_notice)
    _link = link_to("click here", :controller => "ivl_notifications").to_html
    mail({to: user.email.address, subject: "DCHealthLink Notification"}) do |format|
      format.html { render "ivl_notification", :locals => { :user => user, :link => _link}}
    end
  end

  def lawfully_ineligible(user)
    notice = Notice.new(user.email, {:notice_data => {:user => user}, :template => "notices/9cindividual.html.erb"})
    attachments["notice.pdf"] = File.read(notice.send_paper_notice)
    _link = link_to("click here", :controller => "ivl_notifications").to_html
    mail({to: user.email.address, subject: "DCHealthLink Notification"}) do |format|
      format.html { render "ivl_notification", :locals => { :user => user, :link => _link}}
    end
  end
  
end 

