class TranslationsController < ApplicationController
  def index
    @translations = MongoI18n.store
  end

  def create
    I18n.backend.store_translations(params[:locale], {params[:key] => params[:value]}, escape: false)
    redirect_to translations_url, :notice => "Added translations"
  end
end

