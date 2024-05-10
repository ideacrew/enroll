# frozen_string_literal: true

class Exchanges::SecurityQuestionsController < ApplicationController
  include ::L10nHelper

  layout 'single_column'

  before_action :check_feature_enabled

  def index
    authorize SecurityQuestion, :index?
    @questions = SecurityQuestion.all
  end

  def new
    authorize SecurityQuestion, :new?
    @question = SecurityQuestion.new
  end

  def create
    authorize SecurityQuestion, :create?
    @question = SecurityQuestion.new(security_question_params)
    if @question.save
      redirect_to exchanges_security_questions_path, notice: 'Question was successfully created'
    else
      render :new
    end
  end

  def edit
    authorize SecurityQuestion, :edit?
    @question = SecurityQuestion.find(params[:id])
  end

  def update
    authorize SecurityQuestion, :update?
    @question = SecurityQuestion.find(params[:id])
    if @question.safe_to_edit_or_delete? && @question.update_attributes(security_question_params)
      redirect_to exchanges_security_questions_path, notice: 'Question was updated successfully'
    else
      render :edit
    end
  end

  def destroy
    authorize SecurityQuestion, :destroy?
    @question = SecurityQuestion.find(params[:id])
    if @question.safe_to_edit_or_delete?
      @question.destroy
      notice = 'Question was deleted successfully.'
    else
      notice = 'That Question is already in use'
    end
    redirect_to exchanges_security_questions_path, notice: notice
  end

  private

  # Checks if the security questions feature is enabled.
  # If the feature is not enabled, it sets a flash error message and redirects the user to the root path.
  #
  # @return [nil, ActionController::Redirecting] Returns nil if the security questions feature is enabled,
  # otherwise it redirects the user to the root path.
  def check_feature_enabled
    return if Settings.aca.security_questions

    flash[:error] = l10n('exchanges.security_questions.denied_access_message')
    redirect_to root_path
  end

  def security_question_params
    params.require(:security_question).permit(:title, :visible)
  end

  def set_question
    @question = SecurityQuestion.find(params[:id])
  end

end
