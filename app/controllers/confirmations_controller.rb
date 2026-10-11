# frozen_string_literal: true

# Confirmação de e-mail do cadastro (US09, #32). O link do e-mail confirma na
# hora; o formulário de reenvio regenera o token, o que invalida o anterior.
class ConfirmationsController < ApplicationController
  # O link chega por e-mail, então precisa funcionar sem sessão.
  def edit
    @user = User.find_by(email: params[:email].to_s.downcase)
    return generic_alert unless @user && valid_token?

    if @user.confirmed?
      generic_alert
    else
      @user.confirm
      flash[:notice] = "E-mail confirmado com sucesso! Faça login para continuar."
      redirect_to(entrar_path)
    end
  end

  def new; end

  def create
    user = User.find_by(email: params[:email].to_s.downcase)
    if user && !user.confirmed?
      user.create_confirmation_digest
      UserMailer.confirmation(user).deliver_now
    end

    # Mesma resposta para e-mail que existe e para o que não existe: a tela de
    # reenvio não pode virar um oráculo de quais e-mails têm conta.
    flash[:notice] = "Se este e-mail existir e não estiver confirmado, enviaremos um novo link."
    redirect_to(entrar_path)
  end

  private

  def valid_token?
    @user.confirmation_authenticated?(params[:token]) && !@user.confirmation_expired?
  end

  def generic_alert
    flash[:alert] = "Link de confirmação inválido, expirado ou já utilizado."
    redirect_to(entrar_path)
  end
end
