class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      sign_in(user, remember_me: params[:remember_me] == "1")
      redirect_to root_path, notice: "Login realizado com sucesso!"
    else
      flash[:alert] = "E-mail ou senha inválidos"
      render :new
    end
  end

  def destroy
    sign_out
    redirect_to root_path, notice: "Logout realizado com sucesso!"
  end
end
