class IvlNotificationMailer < ApplicationMailer
  include ActionView::Helpers::UrlHelper
  after_action :send_inbox_notice
   
  def lawful_presence_verified(user)
    @user = user
    @view_type = "lawful_presence_verified"
    notice = Notice.new(user.email, {:notice_data => {:user => user}, :template => "notices/9cindividual.html.erb"})    
    attachments["notice.pdf"] = File.read(notice.send_paper_notice)
    mail({to: user.email.address, subject: "DCHealthLink Notification"}) do |format|
      format.html { render "ivl_notification", :locals => { :user => user, :link => _link}}
    end
  end

  def lawful_presence_unverified(user)
    @user = user
    @view_type = "lawful_presence_unverified"
    notice = Notice.new(user.email, {:notice_data => {:user => user}, :template => "notices/9findividual.html.erb"})
    attachments["notice.pdf"] = File.read(notice.send_paper_notice)
    mail({to: user.email.address, subject: "DCHealthLink Notification"}) do |format|
      format.html { render "ivl_notification", :locals => { :user => user}}
    end
  end

  def lawfully_ineligible(user)
    @user = user
    @view_type = "lawfully_ineligible"
    notice = Notice.new(user.email, {:notice_data => {:user => user}, :template => "notices/11individual.html.erb"})
    attachments["notice.pdf"] = File.read(notice.send_paper_notice)
    mail({to: user.email.address, subject: "DCHealthLink Notification"}) do |format|
      format.html { render "ivl_notification", :locals => { :user => user}}
    end
  end
  
  private
  
  def send_inbox_notice
    if @user.parent && (to_inbox = @user.parent.inbox)
      @link = link_to("click here", :controller => "consumer_profiles", :action => "notification", :id => user.id, :view => @view_type).html_safe
      new_message = to_inbox.messages.build(:subject => "DCHealthLink Notification", :body => "Please #{@link} to view the file")
      new_message.folder = Message::FOLDER_TYPES[:inbox]
      to_inbox.post_message(new_message)
      to_inbox.save!
    end
  end
  
end 

