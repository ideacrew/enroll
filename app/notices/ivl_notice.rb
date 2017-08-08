class IvlNotice < Notice

  include ActionView::Helpers::NumberHelper

  Required= Notice::Required + []

  def initialize(options ={})
    super
  end

  def deliver
    build
    append_hbe
    generate_pdf_notice
    attach_blank_page(notice_path)
    attach_dchl_rights
    prepend_envelope
    upload_and_send_secure_message

    if recipient.consumer_role.can_receive_electronic_communication?
      send_generic_notice_alert
    end

    if recipient.consumer_role.can_receive_paper_communication?
      store_paper_notice
    end
  end

  def prepend_envelope
    envelope = Envelope.new
    envelope.fill_envelope(notice, mpi_indicator)
    envelope.render_file(envelope_path)
    join_pdfs_with_path [envelope_path, notice_path]
  end

  def append_hbe
    notice.hbe = PdfTemplates::Hbe.new({
      url: Settings.site.home_url,
      phone: phone_number_format(Settings.contact_center.phone_number),
      email: Settings.contact_center.email_address,
      short_url: "#{Settings.site.short_name.gsub(/[^0-9a-z]/i,'').downcase}.com",
      address: PdfTemplates::NoticeAddress.new({
        street_1: "100 K ST NE",
        street_2: "Suite 100",
        city: "Washington DC",
        state: "DC",
        zip: "20005"
      })
    })
  end

  def phone_number_format(number)
    number_to_phone(number.gsub(/^./, "").gsub('-',''), area_code: true)
  end

  def attach_dchl_rights
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'dchl_rights.pdf')]
  end

  def attach_taglines
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'taglines.pdf')]
  end

  def attach_appeals
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'ivl_appeal_rights.pdf')]
  end

  def attach_non_discrimination
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'ivl_non_discrimination.pdf')]
  end

  def join_pdfs_with_path(pdfs, path = nil)
    pdf = File.exists?(pdfs[0]) ? CombinePDF.load(pdfs[0]) : CombinePDF.new
    pdf << CombinePDF.load(pdfs[1])
    path_to_save = path.nil? ? notice_path : path
    pdf.save path_to_save
  end

  def attach_blank_page(template_path = nil)
    path = template_path.nil? ? notice_path : template_path
    blank_page = Rails.root.join('lib/pdf_templates', 'blank.pdf')
    page_count = Prawn::Document.new(:template => path).page_count
    if (page_count % 2) == 1
      join_pdfs_with_path([path, blank_page], path)
    end
  end

  # def join_pdfs(pdfs)
  #   Prawn::Document.generate(notice_path, {:page_size => 'LETTER', :skip_page_creation => true}) do |pdf|
  #     pdfs.each do |pdf_file|
  #       if File.exists?(pdf_file)
  #         pdf_temp_nb_pages = Prawn::Document.new(:template => pdf_file).page_count

  #         (1..pdf_temp_nb_pages).each do |i|
  #           pdf.start_new_page(:template => pdf_file, :template_page => i)
  #         end
  #       end
  #     end
  #   end
  # end
end