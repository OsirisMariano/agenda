# frozen_string_literal: true

require "rails_helper"

RSpec.describe(ContactsCsvExporter) do
  let(:user) { create_user }

  # Lê o CSV gerado em linhas, ignorando o BOM — as asserções de conteúdo
  # ficam legíveis e não dependem de aspas ou quebras de linha.
  def rows_of(contacts)
    CSV.parse(described_class.new(contacts).to_csv.delete_prefix(described_class::BOM))
  end

  describe "#to_csv" do
    context "sem contatos" do
      it "gera apenas a linha de cabeçalho" do
        expect(rows_of([])).to(eq([["nome", "telefone", "e-mail", "endereço", "notas"]]))
      end
    end

    context "com contatos" do
      it "gera uma linha por contato, com os cinco campos na ordem do cabeçalho" do
        ana = create_contact(user, name: "Ana Silva", phone: "(11) 98888-1234")
        bruno = create_contact(user, name: "Bruno Costa", phone: "(11) 97777-1234")

        expect(rows_of([ana, bruno])).to(eq([
          ["nome", "telefone", "e-mail", "endereço", "notas"],
          ["Ana Silva", "(11) 98888-1234", nil, nil, nil],
          ["Bruno Costa", "(11) 97777-1234", nil, nil, nil],
        ]))
      end

      it "preenche os campos opcionais informados" do
        carla = create_contact(
          user,
          name: "Carla Dias",
          phone: "(11) 96666-1234",
          email: "carla@exemplo.com",
          address: "Rua dos Ipês, 50",
          notes: "Colega do trabalho",
        )

        expect(rows_of([carla]).last).to(
          eq(["Carla Dias", "(11) 96666-1234", "carla@exemplo.com", "Rua dos Ipês, 50", "Colega do trabalho"]),
        )
      end

      it "mantém campos opcionais vazios quando não informados" do
        ana = create_contact(user, name: "Ana Silva", phone: "(11) 98888-1234")

        expect(rows_of([ana]).last.compact).to(eq(["Ana Silva", "(11) 98888-1234"]))
      end
    end

    context "conteúdo dos valores" do
      it "escapa vírgula, aspas e quebra de linha" do
        contact = create_contact(user, name: "Silva, Ana \"Santos\"", notes: "Linha 1\nLinha 2")

        expect(rows_of([contact]).last).to(
          eq(["Silva, Ana \"Santos\"", contact.phone, nil, nil, "Linha 1\nLinha 2"]),
        )
      end

      it "preserva acentos em UTF-8" do
        contact = create_contact(user, name: "João Coração", address: "Av. São João, 100")

        expect(rows_of([contact]).last).to(include("João Coração", "Av. São João, 100"))
      end
    end

    context "formato do arquivo" do
      it "prefixa o BOM UTF-8 para o Excel não quebrar os acentos" do
        csv = described_class.new([]).to_csv

        expect(csv).to(start_with(described_class::BOM))
        expect(csv.encoding).to(eq(Encoding::UTF_8))
      end

      it "usa vírgula como separador de colunas" do
        contact = create_contact(user, name: "Ana", phone: "(11) 98888-1234")

        expect(described_class.new([contact]).to_csv).to(include("nome,telefone,e-mail,endereço,notas"))
      end
    end

    it "preserva a ordem recebida, sem reordenar" do
      bruno = create_contact(user, name: "Bruno Costa")
      ana = create_contact(user, name: "Ana Silva")

      expect(rows_of([bruno, ana]).drop(1).map(&:first)).to(eq(["Bruno Costa", "Ana Silva"]))
    end
  end
end
