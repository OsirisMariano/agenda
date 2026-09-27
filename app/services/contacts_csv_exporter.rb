# frozen_string_literal: true

require "csv"

# Monta o arquivo CSV de exportação dos contatos.
#
# O BOM no início do arquivo é o que faz o Excel abrir os acentos
# corretamente — sem ele o UTF-8 vira lixo na planilha. O arquivo é gerado
# sob demanda e nunca gravado no servidor (RN05).
class ContactsCsvExporter
  BOM = "\xEF\xBB\xBF"
  HEADERS = ["nome", "telefone", "e-mail", "endereço", "notas"].freeze
  COLUMNS = [:name, :phone, :email, :address, :notes].freeze

  def initialize(contacts)
    @contacts = contacts
  end

  def to_csv
    BOM + CSV.generate(col_sep: ",", write_headers: true, headers: HEADERS) do |csv|
      @contacts.each do |contact|
        csv << COLUMNS.map { |column| contact.public_send(column) }
      end
    end
  end
end
