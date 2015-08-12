class Notice

  attr_accessor :from, :to, :subject, :template, :notice_data, :mkt_kind

  def initialize(recipient, args = {})
    @template = args[:template]
    @email_notice = args[:email_notice] || true
    @paper_notice = args[:paper_notice] || true
    @mailer = args[:mailer] || ApplicationMailer
  end

  def html
    ApplicationController.new.render_to_string({ 
      template: @template, 
      locals: @notice_data
      })
  end

  def pdf
    WickedPdf.new.pdf_from_string(
      self.html
      # margin:  {  
      #   top: 10,
      #   bottom: 10,
      #   left: 20,
      #   right: 20 
      # },
      # header:  {   
      #   :center => "Center",
      #   :left => "Left",
      #   :right => "Right"      },   
      # footer: {
      #   :center => "Center",
      #   :left => "Left",
      #   :right => "Right"
      # }
    )
  end

  def deliver
    send_email_notice if @email_notice
    send_paper_notice if @paper_notice
  end

  def send_email_notice
    @mailer.notice_email(self).deliver_now
  end

  def send_paper_notice
    notice_path = Rails.root.join('pdfs','notice.pdf')
    File.open(notice_path, 'wb') do |file|
      file << self.pdf
    end
  end

  def save_html
    File.open(Rails.root.join('pdfs','notice.html'), 'wb') do |file|
      file << self.html
    end
  end
end

