class Insured::InboxesController < InboxesController
  def 
  	puts 'the right class'
    if HbxPortal.count > 0
      @hbx_portal = HbxPortal.try(params[:id]) || HbxPortal.first
    else  
      @hbx_portal = HbxPortal.new
      @hbx_portal.save
      m = Message.new
      m.subject = 'Portal test message'
      m.sender_id=current_user.id
      @hbx_portal.inbox.messages << m
      @hbx_portal.inbox.messages << m
      @hbx_portal.save
    end
  end
end
