# frozen_string_literal: true

require "csv"

# Importa contatos de um arquivo CSV para a conta do usuário logado.
#
# A importação nunca sobrescreve nem apaga nada (RN01): cada linha do arquivo
# vira um contato novo. As linhas válidas entram e as inválidas são devolvidas
# no relatório com número da linha e campo culpado (RN04) — um telefone
# repetido é erro reportado, nunca sucesso silencioso (RN02).
class ContactsCsvImporter
  # Arquivo acima disso é recusado antes mesmo de ser lido na memória.
  MAX_SIZE = 5.megabytes
  BOM = "\xEF\xBB\xBF"
  REQUIRED_HEADERS = ["nome", "telefone"].freeze

  # Cabeçalho normalizado (minúsculo, sem acento, sem espaço/hífen) => atributo.
  # Aceita "E-mail" e "email", "Endereço" e "endereco" como a mesma coluna.
  COLUMNS = {
    "nome" => :name,
    "telefone" => :phone,
    "email" => :email,
    "endereco" => :address,
    "notas" => :notes,
  }.freeze

  # Rótulo em pt-BR dos campos no relatório de erro.
  FIELD_LABELS = {
    name: "nome",
    phone: "telefone",
    email: "e-mail",
    address: "endereço",
    notes: "notas",
  }.freeze

  # Prefixos que o Excel/Sheets interpreta como fórmula (ver sanitize_formula).
  FORMULA_PREFIXES = ["=", "+", "-", "@", "\t", "\r"].freeze

  # Uma linha que não entrou, com o número da linha no arquivo e o campo culpado.
  LineError = Struct.new(:line, :field, :message) do
    def to_s
      "Linha #{line}: #{field} #{message}"
    end
  end

  # Resumo da importação: quantas linhas entraram e quais falharam.
  class Result
    attr_reader :total, :imported, :errors

    def initialize(total:, imported:, errors:)
      @total = total
      @imported = imported
      @errors = errors
    end

    def any_errors?
      errors.any?
    end

    def failed
      total - imported
    end
  end

  # Arquivo ilegível (vazio, sem as colunas obrigatórias, grande demais ou fora
  # de UTF-8). A mensagem já é exibível na tela.
  class InvalidFile < StandardError; end

  def initialize(user:, file:)
    @user = user
    @file = file
  end

  def call
    table = parse
    imported = 0
    errors = []

    table.each_with_index do |row, index|
      # A linha 1 do arquivo é o cabeçalho, então o primeiro dado é a linha 2 —
      # é assim que o usuário enxerga a planilha.
      line = index + 2
      contact = @user.contacts.build(attributes_from(row))

      if contact.save
        imported += 1
      else
        errors.concat(errors_from(contact, line))
      end
    end

    Result.new(total: table.size, imported: imported, errors: errors)
  end

  private

  def parse
    table = CSV.parse(content, headers: true, skip_blanks: true)
    validate_headers!(table.headers)
    table
  rescue CSV::MalformedCSVError
    raise InvalidFile, "Não foi possível ler o arquivo CSV. Confira a formatação das linhas."
  end

  def content
    @content ||= begin
      raise InvalidFile, "Selecione um arquivo CSV para importar." if @file.blank?

      validate_size!
      read_utf8.delete_prefix(BOM)
    end
  end

  def validate_size!
    return if @file.size <= MAX_SIZE

    raise InvalidFile, "Arquivo muito grande: o limite é de #{MAX_SIZE / 1.megabyte} MB."
  end

  # O tempfile do upload chega em binário (ASCII-8BIT). Sem converter, o
  # delete_prefix do BOM estoura o encoding e os acentos viram lixo no parse.
  def read_utf8
    raw = @file.read.dup.force_encoding(Encoding::UTF_8)
    raise InvalidFile, "O arquivo precisa estar codificado em UTF-8." unless raw.valid_encoding?

    raw
  end

  def validate_headers!(headers)
    raise InvalidFile, "O arquivo está vazio." if headers.blank?

    present = headers.map { |header| normalize(header) }
    missing = REQUIRED_HEADERS - present
    return if missing.empty?

    raise InvalidFile, "O arquivo precisa ter as colunas: #{missing.join(", ")}."
  end

  # Só os campos preenchidos entram no contato — coluna vazia vira nil para o
  # model validar (e não "", que reprovaria em e-mail, endereço e notas).
  def attributes_from(row)
    attributes = {}

    row.each do |header, value|
      attribute = COLUMNS[normalize(header)]
      next if attribute.nil?

      cell = sanitize_formula(value.to_s.strip)
      attributes[attribute] = cell if cell.present?
    end

    attributes
  end

  # CSV de terceiros é o vetor de entrada da injeção de fórmula (§12.4 do PRD):
  # uma célula começando com =, +, -, @, tab ou CR vira comando executável no
  # Excel/Sheets quando o arquivo é aberto. O prefixo ' força o texto e neutraliza
  # a execução; um valor já escapado não recebe um segundo prefixo, para o
  # round-trip exportar → importar → exportar não degradar o dado.
  def sanitize_formula(value)
    return value if value.start_with?("'")
    return value unless FORMULA_PREFIXES.any? { |prefix| value.start_with?(prefix) }

    "'#{value}"
  end

  def errors_from(contact, line)
    contact.errors.map do |error|
      LineError.new(
        line: line,
        field: FIELD_LABELS[error.attribute] || error.attribute.to_s,
        message: error.message,
      )
    end
  end

  # "E-mail", "endereço " e "Telefone" viram a mesma chave de COLUMNS.
  def normalize(header)
    header
      .to_s
      .strip
      .downcase
      .unicode_normalize(:nfd)
      .gsub(/\p{Mn}/, "")
      .delete(" -")
  end
end
