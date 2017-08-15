class Exchanges::SecurityQuestionsController < ApplicationController
  layout 'single_column'

  def index
    @questions = SecurityQuestion.all
  end

  def new
    @question = SecurityQuestion.new
  end

  def create
    @question = SecurityQuestion.new(security_question_params)
    # binding.pry
    if @question.save
      redirect_to exchanges_security_questions_path, notice: 'Question was successfully created'
    else
      render :new
    end
  end

  def edit
    @question = SecurityQuestion.find(params[:id])
  end

  def update
    @question = SecurityQuestion.find(params[:id])
    if @question.update_attributes(security_question_params)
      redirect_to exchanges_security_questions_path, notice: 'Question was updated successfully'
    else
      render :edit
    end
  end

  def destroy
    @question = SecurityQuestion.find(params[:id])
    @question.destroy
    redirect_to exchanges_security_questions_path, notice: 'Question was deleted successfully.'
  end

  private

  def security_question_params
    params.require(:security_question).permit(:title, :visible)
  end

  def set_question
    @question = SecurityQuestion.find(params[:id])
  end

end
