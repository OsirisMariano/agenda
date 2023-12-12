Rails.application.routes.draw do

  root            to: 'static_pages#index'
  
  # Rotas sobre o software
  get 'sobre',    to: 'static_pages#sobre'
  get 'contato',  to: 'static_pages#contato'

  # Rotas para registro de usuários
  get 'cadastrar', to: 'users#new'
  post 'cadastrar', to: 'users#create'
  
  # Rotas para sessão (login/logout)
  get 'entrar',   to: 'sessions#new'
  post 'entrar',  to: 'sessions#create'
  delete 'sair',  to: 'sessions#destroy'

  resources :users, only: [:show, :new, :create, :edit, :update] do
    resources :contacts, only: [:index, :new, :create, :edit, :update, :destroy]
  end
  resources :sessions, only: [:new, :create, :destroy]

end