# frozen_string_literal: true

Rails.application.routes.draw do
  get 'sessions/new'
  get "users/new"
  root to: "static_pages#index"

  # Rotas sobre o software
  get "sobre",    to: "static_pages#sobre"

  get "entrar", to: "sessions#new", as: "entrar"
  post "entrar", to: "sessions#create"
  get "sair", to: "sessions#destroy", as: "sair"
  delete "sair", to: "sessions#destroy"
  get "cadastro", to: "users#new", as: "cadastro"
  get "usuarios", to: "users#index"

  resources :contacts, only: [:index, :new, :create, :edit, :update, :destroy]
  resources :users, only: [:index, :create]
end
