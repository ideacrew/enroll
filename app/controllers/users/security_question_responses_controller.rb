class Users::SecurityQuestionResponsesController < ApplicationController
  def create
    responses = params[:security_question_responses]
    responses.each do |response|
      user.security_question_responses << SecurityQuestionResponse.new(security_question_id: response[:security_question_id], question_answer: response[:question_answer])
    end
    unless user.save!
      #handle error
    end
  end

  def challenge
    if user_from_email
      @security_question = user_from_email.security_question_responses[rand(0..2)]
    else

    end
  end

  def authenticate
    if challenge_question.matching_response? params[:security_question_response][:question_answer]
      ## success
      ## respond with a hashed token and save to compare with reset pw form ?
    else
      ## bad
    end
  end

  private
  helper_method :user_from_email

  def challenge_question
    challenge = user.security_question_responses.where(security_question_id: params[:security_question_response][:security_question_id]).first
    pp challenge
    @challenge_question ||= challenge
  end

  def user
    @user ||= User.find(params[:user_id])
  end

  def user_from_email
    @user ||= User.find_by(email: params[:user][:email])
  end
end
