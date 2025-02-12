# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include DeviseTokenAuth::Concerns::SetUserByToken

  protect_from_forgery with: :null_session

  rescue_from ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved, ActiveRecord::RecordNotDestroyed,
              ActiveRecord::RecordNotUnique, with: :unprocessable_entity
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def unprocessable_entity(exception)
    render json: { message: exception.record.errors.full_messages.join(", ") },
           status: :unprocessable_entity
  end

  def not_found(_exception)
    render json: { message: "Not Found" }, status: :not_found
  end
end
