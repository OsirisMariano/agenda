# frozen_string_literal: true

module SessionsHelper
  REMEMBER_ME_EXPIRATION = 2.weeks

  def sign_in(user, remember_me: false)
    if remember_me
      cookies.signed[:user_id] = { value: user.id, expires: REMEMBER_ME_EXPIRATION.from_now }
    else
      session[:user_id] = user.id
    end
  end

  def sign_out
    session.delete(:user_id)
    cookies.delete(:user_id)
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id] || cookies.signed[:user_id])
  end

  def user_signed_in?
    !current_user.nil?
  end
end
