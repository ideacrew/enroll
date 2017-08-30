module Notifier
  class NoticeKindsController < Notifier::ApplicationController

    layout 'notifier/single_column'

    def index
      @notice_kinds = Notifier::NoticeKind.all
      @datatable = Effective::Datatables::NoticesDatatable.new
    end

    def new
      @notice_kind = Notifier::NoticeKind.new
      @notice_kind.template = Notifier::Template.new
    end

    def edit
      @notice_kind = Notifier::NoticeKind.find(params[:id])
      render :layout => 'notifier/application'
    end

    def create
      template = Template.new(notice_params.delete('template'))
      notice_kind = NoticeKind.new(notice_params)
      notice_kind.template = template

      if notice_kind.save
        flash[:notice] = 'Notice created successfully'
      end
      redirect_to notice_kinds_path
    end

    def update
      notice_kind = Notifier::NoticeKind.find(params['id'])
      notice_kind.update_attributes(notice_params)

      flash[:notice] = 'Notice content updated successfully'
      redirect_to notice_kinds_path
    end

    def preview
      notice_kind = Notifier::NoticeKind.find(params[:id])
      notice_kind.generate_pdf_notice

      send_file "#{Rails.root}/public/NoticeTemplate.pdf", 
        :type => 'application/pdf', 
        :disposition => 'inline'
    end

    def delete_notices
      Notifier::NoticeKind.where(:id.in => params['ids']).each do |notice|
        notice.delete
      end

      flash[:notice] = 'Notices deleted successfully'
      redirect_to notice_kinds_path
    end

    def get_tokens
      builder = params['builder'] || 'Notifier::MergeDataModels::EmployerProfile'
      tokens = builder.constantize.new.editor_tokens

      respond_to do |format|
        format.html
        format.json {render json: tokens}
      end
    end

    def get_placeholders
      placeholders = Notifier::MergeDataModels::EmployerProfile.new.place_holders

      respond_to do |format|
        format.html
        format.json {render json: placeholders}
      end
    end

    private

    def notice_params
      params.require(:notice_kind).permit(:title, :description, :receipient, {:template => [:raw_body]})
    end
  end
end
