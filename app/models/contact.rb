# frozen_string_literal: true

class Contact < ApplicationRecord
  PHONE_REGEX = /\A(\+\d{1,3}[-\s.]?)?\(?\d{2}\)?[-\s.]?\d{4,5}[-\s.]?\d{4}\z/
  EMAIL_REGEX = URI::MailTo::EMAIL_REGEXP

  # Limiar do `word_similarity` (US07). Medido em dados reais: um nome idêntico
  # pontua 1.0, erro de um caractere 0.60-0.67, plural 0.50, e a palavra
  # vizinha mais parecida ("ana" contra "Joana") 0.50. Com 0.4 entra o erro de
  # digitação sem entrar falso positivo.
  #
  # O que fica de fora, de propósito: transposição de letras ("jocao" para
  # "Joao") pontua 0.33. O coeficiente de trigramas mede sobreposição de
  # caracteres, e trocar duas letras adjacentes destrói dois trigramas de uma
  # vez -- nenhum limiar que pegasse a transposição deixaria de ser busca.
  FUZZY_THRESHOLD = 0.4

  belongs_to :user

  validates :name, presence: true, length: { maximum: 50 }
  validates :phone,
    presence: true,
    format: { with: PHONE_REGEX, message: "inválido. Use o formato (XX) XXXXX-XXXX." },
    uniqueness: { scope: :user_id }
  validates :email,
    format: { with: EMAIL_REGEX, allow_blank: true, message: "inválido." },
    length: { maximum: 255, allow_blank: true }
  validates :address, length: { maximum: 255 }
  validates :notes, length: { maximum: 1000 }

  # `unaccent` é `STABLE`, não `IMMUTABLE` (verificado no Postgres 12.3), então
  # não pode entrar em índice de expressão. O recorte por `user_id`, que já tem
  # índice, é o que segura a consulta.
  scope :search, ->(query) {
    term = query.to_s.strip
    next none if term.empty?

    where(
      <<~SQL.squish,
        unaccent(name) ILIKE unaccent(:pattern)
        OR unaccent(email) ILIKE unaccent(:pattern)
        OR phone ILIKE :pattern
        OR word_similarity(unaccent(:term), unaccent(name)) >= :threshold
        OR word_similarity(unaccent(:term), unaccent(email)) >= :threshold
      SQL
      pattern: "%#{term}%",
      term: term,
      threshold: FUZZY_THRESHOLD,
    )
  }
end
