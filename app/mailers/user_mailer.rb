# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def password_reset(user)
    @user = user
    @token = user.reset_token
    mail(to: user.email, subject: "Recuperação de senha")
  end

  def confirmation(user)
    @user = user
    @token = user.confirmation_token
    mail(to: user.email, subject: "Confirme seu e-mail")
  end
end
