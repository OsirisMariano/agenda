# frozen_string_literal: true

require "rails_helper"

RSpec.describe(ContactsCsvImporter) do
  let(:user) { create_user }
  let(:other_user) { create_user }
  let(:headers) { "nome,telefone,e-mail,endereço,notas" }

  # StringIO com o conteúdo do CSV — é o mesmo contrato do objeto que o
  # controller recebe do upload (tempfile do Rack), então size/read são reais.
  def csv_file(conteudo)
    StringIO.new(conteudo)
  end

  def import(conteudo, para: user)
    import_file(csv_file(conteudo), para: para)
  end

  def import_file(file, para: user)
    described_class.new(user: para, file: file).call
  end

  describe "#call" do
    context "arquivo válido" do
      it "cria um contato por linha" do
        result = import("#{headers}\nAna Silva,(11) 98888-1234\nBruno Costa,(11) 97777-1234\n")

        expect(result.total).to(eq(2))
        expect(result.imported).to(eq(2))
        expect(result.errors).to(be_empty)
        expect(user.contacts.pluck(:name)).to(eq(["Ana Silva", "Bruno Costa"]))
      end

      it "preenche os cinco campos de cada linha" do
        import(
          "#{headers}\n" \
            "Carla Dias,(11) 96666-1234,carla@exemplo.com,\"Rua dos Ipês, 50\",Colega do trabalho\n",
        )

        carla = user.contacts.sole
        expect(carla.name).to(eq("Carla Dias"))
        expect(carla.phone).to(eq("(11) 96666-1234"))
        expect(carla.email).to(eq("carla@exemplo.com"))
        expect(carla.address).to(eq("Rua dos Ipês, 50"))
        expect(carla.notes).to(eq("Colega do trabalho"))
      end

      it "vincula os contatos ao usuário que está importando (RN03)" do
        import("#{headers}\nAna Silva,(11) 98888-1234\n")

        expect(user.contacts.count).to(eq(1))
        expect(other_user.contacts.count).to(eq(0))
      end

      it "aceita o cabeçalho com caixa e acentos diferentes" do
        import("NOME,Telefone,E-MAIL,Endereço,Notas\nAna Silva,(11) 98888-1234,ana@exemplo.com,Rua A,nota\n")

        ana = user.contacts.sole
        expect(ana.phone).to(eq("(11) 98888-1234"))
        expect(ana.email).to(eq("ana@exemplo.com"))
        expect(ana.address).to(eq("Rua A"))
        expect(ana.notes).to(eq("nota"))
      end

      it "ignora colunas desconhecidas" do
        import("nome,telefone,aniversario,obs\nAna Silva,(11) 98888-1234,10/05,nota\n")

        expect(user.contacts.sole.name).to(eq("Ana Silva"))
        expect(user.contacts.sole.notes).to(be_nil)
      end

      it "descarta espaços em volta dos valores" do
        import("#{headers}\n  Ana Silva  ,  (11) 98888-1234  \n")

        expect(user.contacts.sole.name).to(eq("Ana Silva"))
      end

      it "pula linhas em branco no meio do arquivo" do
        result = import("#{headers}\nAna Silva,(11) 98888-1234\n\nBruno Costa,(11) 97777-1234\n")

        expect(result.total).to(eq(2))
        expect(result.imported).to(eq(2))
      end

      it "ignora o BOM UTF-8 no início do arquivo" do
        result = import("#{ContactsCsvImporter::BOM}#{headers}\nAna Silva,(11) 98888-1234\n")

        expect(result.imported).to(eq(1))
        expect(user.contacts.sole.name).to(eq("Ana Silva"))
      end

      it "aceita um arquivo só com o cabeçalho, sem nenhum contato" do
        result = import("#{headers}\n")

        expect(result.total).to(eq(0))
        expect(result.imported).to(eq(0))
        expect(result.any_errors?).to(be(false))
        expect(user.contacts.count).to(eq(0))
      end
    end

    context "linhas inválidas" do
      it "reporta o número da linha e o campo do telefone inválido (Cenário 3)" do
        result = import(
          "#{headers}\nAna Silva,(11) 98888-1234\nBruno Costa,(11) 97777-1234\nCarla Dias,12345\n",
        )

        expect(result.errors.map(&:to_s)).to(
          eq(["Linha 4: telefone inválido. Use o formato (XX) XXXXX-XXXX."]),
        )
      end

      it "aponta o número da linha contando o cabeçalho como linha 1" do
        result = import("#{headers}\nAna Silva,12345\n")

        expect(result.errors.first.line).to(eq(2))
      end

      it "reporta o campo nome quando ele falta" do
        result = import("#{headers}\n,(11) 98888-1234\n")

        expect(result.errors.map(&:to_s)).to(eq(["Linha 2: nome não pode ser em branco"]))
      end

      it "reaproveita a mensagem do model para nomes longos demais" do
        result = import("#{headers}\n#{"a" * 51},(11) 98888-1234\n")

        expect(result.errors.map(&:to_s)).to(
          eq(["Linha 2: nome Muito grande. Máximo de 50 caracteres"]),
        )
      end

      it "importa as linhas válidas mesmo com uma inválida no meio (RN04)" do
        result = import(
          "#{headers}\nAna Silva,(11) 98888-1234\nCarla Dias,12345\nBruno Costa,(11) 97777-1234\n",
        )

        expect(result.total).to(eq(3))
        expect(result.imported).to(eq(2))
        expect(result.failed).to(eq(1))
        expect(result.any_errors?).to(be(true))
        expect(user.contacts.pluck(:name)).to(eq(["Ana Silva", "Bruno Costa"]))
      end

      it "acumula um erro por campo inválido na mesma linha" do
        result = import("#{headers}\n,12345\n")

        expect(result.errors.map(&:field)).to(eq(["nome", "telefone"]))
        expect(result.imported).to(eq(0))
      end

      it "trata uma linha só com vírgulas como relatório, não como sucesso" do
        result = import("#{headers}\n,,\n")

        expect(result.total).to(eq(1))
        expect(result.imported).to(eq(0))
        expect(result.errors.map(&:to_s)).to(eq([
          "Linha 2: nome não pode ser em branco",
          "Linha 2: telefone não pode ser em branco",
          "Linha 2: telefone inválido. Use o formato (XX) XXXXX-XXXX.",
        ]))
      end
    end

    context "duplicidade (RN01 e RN02)" do
      it "trata telefone repetido dentro do próprio arquivo como erro" do
        result = import("#{headers}\nAna Silva,(11) 98888-1234\nBruno Costa,(11) 98888-1234\n")

        expect(result.imported).to(eq(1))
        expect(result.errors.map(&:to_s)).to(eq(["Linha 3: telefone já cadastrado"]))
      end

      it "trata telefone já cadastrado como erro, sem alterar o contato existente" do
        existente = create_contact(user, name: "Ana Original", phone: "(11) 98888-1234")

        result = import("#{headers}\nAna Nova,(11) 98888-1234\n")

        expect(result.imported).to(eq(0))
        expect(result.errors.map(&:to_s)).to(eq(["Linha 2: telefone já cadastrado"]))
        expect(existente.reload.name).to(eq("Ana Original"))
      end

      it "aceita o mesmo telefone em contas diferentes" do
        create_contact(user, phone: "(11) 98888-1234")

        result = import("#{headers}\nContato de Outro,(11) 98888-1234\n", para: other_user)

        expect(result.imported).to(eq(1))
        expect(other_user.contacts.count).to(eq(1))
      end

      it "nunca apaga nem sobrescreve o que já existe (RN01)" do
        create_contact(user, name: "Ana Original", phone: "(11) 98888-1234")
        create_contact(user, name: "Bruno Original", phone: "(11) 97777-1234")

        import("#{headers}\nAna Nova,(11) 96666-1234\n")

        expect(user.contacts.pluck(:name, :phone)).to(eq([
          ["Ana Original", "(11) 98888-1234"],
          ["Bruno Original", "(11) 97777-1234"],
          ["Ana Nova", "(11) 96666-1234"],
        ]))
      end
    end

    context "injeção de fórmula (§12.4 do PRD)" do
      it "neutraliza valor que começa com sinal de igual" do
        import("#{headers}\nAna Silva,(11) 98888-1234\nMalvina,(11) 96666-1234,,,=1+1\n")

        expect(user.contacts.order(:id).last.notes).to(eq("'=1+1"))
      end

      it "neutraliza os demais prefixos de fórmula" do
        ["+1+1", "-2+3", "@SUM(A1)"].each_with_index do |formula, indice|
          import("#{headers}\nF#{indice},(11) 9888#{indice}-1234,,,#{formula}\n")
        end

        expect(user.contacts.order(:id).last(3).map(&:notes)).to(eq(["'+1+1", "'-2+3", "'@SUM(A1)"]))
      end

      it "não duplica o prefixo quando o valor já vem escapado" do
        import(%(#{headers}\nMalvina,(11) 96666-1234,,,'=1+1\n))

        expect(user.contacts.sole.notes).to(eq("'=1+1"))
      end

      it "deixa valores normais intactos" do
        import("#{headers}\nAna Silva,(11) 98888-1234,ana@exemplo.com,Rua A,10/05\n")

        ana = user.contacts.sole
        expect(ana.email).to(eq("ana@exemplo.com"))
        expect(ana.notes).to(eq("10/05"))
      end

      it "mantém o valor escapado quando o contato volta para o CSV" do
        import("#{headers}\nMalvina,(11) 96666-1234,,,=1+1\n")

        csv = ContactsCsvExporter.new(user.contacts).to_csv.delete_prefix(ContactsCsvExporter::BOM)

        expect(CSV.parse(csv).last.last).to(eq("'=1+1"))
      end
    end

    context "guardrails do arquivo" do
      it "recusa arquivo sem a coluna nome" do
        expect { import("telefone,e-mail\n(11) 98888-1234,x@y.com\n") }.to(
          raise_error(ContactsCsvImporter::InvalidFile, "O arquivo precisa ter as colunas: nome."),
        )
      end

      it "recusa arquivo sem a coluna telefone" do
        expect { import("nome,e-mail\nAna,x@y.com\n") }.to(
          raise_error(ContactsCsvImporter::InvalidFile, "O arquivo precisa ter as colunas: telefone."),
        )
      end

      it "recusa arquivo vazio" do
        expect { import("") }.to(
          raise_error(ContactsCsvImporter::InvalidFile, "O arquivo está vazio."),
        )
      end

      it "recusa CSV malformado" do
        expect { import(%(nome,telefone\n"sem fim,(11) 98888-1234\n)) }.to(
          raise_error(ContactsCsvImporter::InvalidFile, /Não foi possível ler o arquivo CSV/),
        )
      end

      it "recusa arquivo acima do limite de 5 MB (o caso de 50 MB da US06)" do
        file = csv_file("#{headers}\nAna Silva,(11) 98888-1234\n")
        allow(file).to(receive(:size).and_return(50.megabytes))

        expect { import_file(file) }.to(
          raise_error(ContactsCsvImporter::InvalidFile, "Arquivo muito grande: o limite é de 5 MB."),
        )
        expect(user.contacts.count).to(eq(0))
      end

      it "recusa arquivo fora de UTF-8" do
        arquivo = +"nome,telefone\nJo\xE3o Silva,(11) 98888-1234\n"

        expect { import(arquivo) }.to(
          raise_error(ContactsCsvImporter::InvalidFile, "O arquivo precisa estar codificado em UTF-8."),
        )
      end

      it "recusa quando nenhum arquivo foi escolhido" do
        expect { import_file(nil) }.to(
          raise_error(ContactsCsvImporter::InvalidFile, "Selecione um arquivo CSV para importar."),
        )
      end
    end
  end
end
