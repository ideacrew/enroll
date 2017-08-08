module Notifier
  class NoticeKindsController < Notifier::ApplicationController

    def new
      @notice_kind = Notifier::NoticeKind.find('5987104cfb9cddd6a0000005')
    end

    def create
      template = Template.new(notice_params.delete('template'))
      notice_kind = NoticeKind.new(notice_params)
      notice_kind.template = template

      if notice_kind.save
        flash[:notice] = 'Notice created successfully'
      end
      redirect_to new_notice_kind_path
    end

    def update
      template = Notifier::NoticeKind.find(params['id']).template
      template.update_attributes!(raw_body: params['notice_kind']['template']['raw_body'].html_safe)
      flash[:notice] = 'Notice content updated successfully'
      redirect_to new_notice_kind_path
    end

    def preview
      # template = Template.new(raw_body: params['template'])
      # notice_kind = NoticeKind.new(title: 'Sample')
      # notice_kind.template = template
      notice_kind = Notifier::NoticeKind.find('5987104cfb9cddd6a0000005')
      notice_kind.generate_pdf_notice

      render :json => { :message => "notice generated successuflly." }
    end

    def show
      notice_kind = Notifier::NoticeKind.find('5987104cfb9cddd6a0000005')
            # render :inline => notice_kind.template.raw_body.gsub('#{', '<%=').gsub('}','%>'), :layout => 'notifier/pdf_layout'

      render :inline => notice_kind.template.raw_body.gsub('#{-', '<%').gsub('#{', '<%=').gsub('}','%>'), :layout => 'notifier/pdf_layout', :locals => { employer: Notifier::MergeDataModels::EmployerProfile.stubbed_object }

    end

    private

    def notice_params
      params.require(:notice_kind).permit(:title, :description, {:template => [:raw_body]})
    end
  end
end
