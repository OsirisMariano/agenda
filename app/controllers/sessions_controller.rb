# frozen_string_literal: true

class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      # Senha certa, e-mail não confirmado: sem sessão. Quem chega aqui já
      # provou a senha, então dizer que a conta existe não vaza nada.
      if user.confirmed?
        sign_in(user, remember_me: params[:remember_me] == "1")
        redirect_to(root_path, notice: "Login realizado com sucesso!")
      else
        flash[:alert] = "Confirme seu e-mail antes de entrar."
        redirect_to(reenviar_confirmacao_path)
      end
    else
      flash[:alert] = "E-mail ou senha inválidos"
      render(:new)
    end
  end

  def destroy
    sign_out
    redirect_to(root_path, notice: "Logout realizado com sucesso!")
  end
end
