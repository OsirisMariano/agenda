# frozen_string_literal: true

Rack::Attack.cache.store = Rails.cache

Rack::Attack.throttle("logins/ip", limit: 5, period: 1.minute) do |request|
  request.ip if request.post? && request.path == "/entrar"
end

Rack::Attack.throttled_responder = lambda do |_request|
  [
    429,
    {
      "content-type" => "text/plain; charset=utf-8",
      "retry-after" => "60",
    },
    "Muitas tentativas de login. Tente novamente em 1 minuto.",
  ]
end
