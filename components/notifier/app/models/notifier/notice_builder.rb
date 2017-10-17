module Notifier
  module NoticeBuilder

    def to_html(options = {})
      data_object = (resource.present? ? data_builder : receipient.constantize.stubbed_object)
      render_envelope({receipient: data_object}) + render_notice_body({receipient_klass_name => data_object}) 
    end

    def data_builder
      builder_klass = ['Notifier', 'Builders', receipient.split('::').last].join('::')
      builder = builder_klass.constantize.new
      builder.resource = resource
      builder.append_contact_details

      template.data_elements.each do |element|
        element_retriver = element.split('.').reject{|ele| ele == receipient_klass_name.to_s}.join('_')
        builder.instance_eval(element_retriver)
      end

      builder.merge_model
    end

    def render_envelope(params)
       Notifier::NoticeKindsController.new.render_to_string({
        :template => 'notifier/notice_kinds/template.html.erb', 
        :layout => false,
        :locals => params.merge(notice_number: self.notice_number)
      })
    end

    def render_notice_body(params)
      Notifier::NoticeKindsController.new.render_to_string({ 
        :inline => template.raw_body.gsub('${', '<%=').gsub('#{', '<%=').gsub('}','%>').gsub('[[', '<%').gsub(']]', '%>'),
        :layout => 'notifier/pdf_layout',
        :locals => params
      })
    end

    def save_html
      File.open(Rails.root.join("tmp", "notice.html"), 'wb') do |file|
        file << self.to_html({kind: 'pdf'})
      end
    end 
  
    def to_pdf
      WickedPdf.new.pdf_from_string(self.to_html({kind: 'pdf'}), pdf_options)
    end

    def generate_pdf_notice
      File.open(notice_path, 'wb') do |file|
        file << self.to_pdf
      end

      attach_envelope
      non_discrimination_attachment
      # clear_tmp
    end

    def pdf_options
      {
        margin:  {
          top: 15,
          bottom: 28,
          left: 22,
          right: 22 
        },
        disable_smart_shrinking: true,
        dpi: 96,
        page_size: 'Letter',
        formats: :html,
        encoding: 'utf8',
        header: {
          content: ApplicationController.new.render_to_string({
            template: "notifier/notice_kinds/header_with_page_numbers.html.erb",
            layout: false,
            locals: {notice: self}
            }),
          }
      }
    end

    def notice_path
      Rails.root.join("public", "NoticeTemplate.pdf")
    end

    def non_discrimination_attachment
      join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'ma_shop_non_discrimination_attachment.pdf')]
    end

    def attach_envelope
      join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'ma_envelope_without_address.pdf')]
    end

    def join_pdfs(pdfs)
      pdf = File.exists?(pdfs[0]) ? CombinePDF.load(pdfs[0]) : CombinePDF.new
      pdf << CombinePDF.load(pdfs[1])
      pdf.save notice_path
    end
  end
end