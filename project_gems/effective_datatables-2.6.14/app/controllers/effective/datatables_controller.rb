module Effective
  class DatatablesController < ApplicationController
    skip_log_page_views quiet: true if defined?(EffectiveLogging)

    # This will respond to both a GET and a POST
    def show
      params[:custom_attributes].permit! if params[:custom_attributes].presence
      params[:attributes].permit! if params[:attributes].presence
      params[:scopes].permit! if params[:scopes].presence

      attributes = (params[:attributes].presence || {}).merge(referer: request.referer).merge(custom_attributes: params.try(:custom_attributes, []))
      scopes = (params[:scopes].presence || params[:custom_attributes].presence || {})

      @datatable = find_datatable(params[:id]).try(:new, attributes.merge(scopes).to_hash)
      @datatable.view = view_context if !@datatable.nil?

      EffectiveDatatables.authorized?(@datatable, self, :index, @datatable.try(:collection_class) || @datatable.try(:class))

      respond_to do |format|
        format.html
        format.json {
          if Rails.env.production?
            render :json => (@datatable.to_json rescue error_json)
          else
            render :json => @datatable.to_json
          end
        }
      end

    end

    private

    def find_datatable(id)
      id_plural = id.pluralize == id && id.singularize != id
      klass = "effective/datatables/#{id}".classify

      (id_plural ? klass.pluralize : klass).safe_constantize
    end

    def error_json
      {
        :draw => params[:draw].to_i,
        :data => [],
        :recordsTotal => 0,
        :recordsFiltered => 0,
        :aggregates => [],
        :charts => {}
      }.to_json
    end

  end
end
