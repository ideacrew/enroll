class EmployerMailer < ApplicationMailer

  def notice_email(notice)
    mail({ to: notice.to, subject: notice.subject}) do |format|
      format.html { notice.html }
    end
  end
end
