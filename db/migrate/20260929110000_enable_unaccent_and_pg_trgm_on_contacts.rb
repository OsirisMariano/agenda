# frozen_string_literal: true

# Habilita a busca tolerante a acentos e erros de digitação da US07 (#30)
# sem gem nova: as duas extensions já vêm no postgresql-contrib da imagem
# postgres:12.3, e o usuário postgres é superuser no compose e no CI.
class EnableUnaccentAndPgTrgmOnContacts < ActiveRecord::Migration[7.0]
  def up
    enable_extension("unaccent") unless extension_enabled?("unaccent")
    enable_extension("pg_trgm") unless extension_enabled?("pg_trgm")
  end

  def down
    # As extensions são compartilhadas por todo o banco; derrubá-las aqui
    # derrubaria a busca de qualquer outra tabela que as use.
  end
end
