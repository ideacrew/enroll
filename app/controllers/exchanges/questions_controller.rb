class Exchanges::QuestionsController < ApplicationController
  layout 'single_column'

  def index
    @questions = Question.all
  end

  def new
    @question = Question.new
  end

  def create
    @question = Question.new(question_params)
    # binding.pry
    if @question.save
      redirect_to exchanges_questions_url, notice: 'Question was successfully created'
    else
      render :new
    end
  end

  def edit
    @question = Question.find(params[:id])
  end

  def update
    @question = Question.find(params[:id])
    if @question.update_attributes(question_params)
      redirect_to exchanges_questions_url, notice: 'Question was updated successfully'
    else
      render :edit
    end
  end

  def destroy
    @question = Question.find(params[:id])
    @question.destroy
    redirect_to exchanges_questions_url, notice: 'Question was deleted successfully.'
  end

  private

  def question_params
    params.require(:question).permit(:title, :visible)
  end

  def set_question
    @question = Question.find(params[:id])
  end

end