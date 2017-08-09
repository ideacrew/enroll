class Users::SecurityQuestionResponsesController < ApplicationController
  require 'bcrypt'

  def create
    responses = params[:security_question_responses]
    responses.each do |response|
      response_sha =  BCrypt::Password.create(response[:question_answer])
      user.security_question_responses << SecurityQuestionResponse.new(security_question_id: response[:security_question_id], question_answer: response_sha)
    end
    unless user.save!
      #handle error
    end
  end

  def authenticate
    reverse_hash = BCrypt::Password.new(@security_question_response.question_answer)
    if reverse_hash == params[:security_question_response][:question_answer]
      ## success
      ## respond with a hashed token and save to compare with reset pw form ?
    else
      ## bad
    end
  end

  private

  def user
    @user ||= User.find(params[:user_id])
  end

  def security_question_response
    @security_question_response ||= SecurityQuestionResponse.find(params[:id])
  end
end
