# frozen_string_literal: true

require "rails_helper"

RSpec.describe("Importação de contatos", type: :request) do
  let(:user) { create_user }
  let(:other_user) { create_user }
  let(:headers) { "nome,telefone,e-mail,endereço,notas" }

  def login(usuario)
    post(entrar_path, params: { email: usuario.email, password: "123456" })
  end

  # Envia o conteúdo como upload multipart, que é o caminho real do formulário.
  def importar(conteudo, filename: "contatos.csv")
    file = Tempfile.new([File.basename(filename, ".*"), File.extname(filename)])
    file.write(conteudo)
    file.rewind

    post(importar_contacts_path, params: { arquivo: Rack::Test::UploadedFile.new(file.path, "text/csv") })
  ensure
    file&.close!
  end

  describe "POST /contacts/importar" do
    context "sem autenticação" do
      it "redireciona para o login e não importa nada (Cenário 5)" do
        expect { importar("#{headers}\nAna Silva,(11) 98888-1234\n") }.not_to(change(Contact, :count))

        expect(response).to(redirect_to(entrar_url))
      end
    end

    context "arquivo válido" do
      before { login(user) }

      it "cria os contatos e avisa quantos entraram" do
        importar("#{headers}\nAna Silva,(11) 98888-1234\n")

        expect(response).to(redirect_to(contacts_path))
        follow_redirect!
        expect(response.body).to(include("1 contato importado com sucesso!"))
        expect(user.contacts.sole.name).to(eq("Ana Silva"))
      end

      it "usa o plural no aviso quando entra mais de um contato" do
        importar("#{headers}\nAna Silva,(11) 98888-1234\nBruno Costa,(11) 97777-1234\n")

        expect(flash[:notice]).to(eq("2 contatos importados com sucesso!"))
      end

      it "mostra o contato importado na listagem" do
        importar("#{headers}\nAna Silva,(11) 98888-1234\n")

        follow_redirect!
        expect(response.body).to(include("Ana Silva"))
      end

      it "importa para a conta logada e não encosta na de outro usuário (RN03)" do
        create_contact(other_user, name: "Contato de Outro", phone: "(11) 95555-1234")

        importar("#{headers}\nAna Silva,(11) 98888-1234\n")

        expect(user.contacts.pluck(:name)).to(eq(["Ana Silva"]))
        expect(other_user.contacts.pluck(:name)).to(eq(["Contato de Outro"]))
      end

      it "avisa quando o arquivo não tem nenhuma linha" do
        importar("#{headers}\n")

        expect(flash[:alert]).to(eq("O arquivo não tem nenhum contato para importar."))
      end
    end

    context "ida e volta: exportar e importar em outra conta (Cenário 2)" do
      it "recria os contatos idênticos, com acentos e campos extras" do
        create_contact(
          user,
          name: "Ana Silva",
          phone: "(11) 98888-1234",
          email: "ana@exemplo.com",
          address: "Rua das Flores, 10",
          notes: "Aniversário em 10/05",
        )
        create_contact(user, name: "João Coração", phone: "(11) 97777-1234")
        create_contact(other_user, name: "Contato de Outro", phone: "(11) 96666-1234")

        login(user)
        get(exportar_contacts_path)
        exportado = response.body
        expect(exportado).to(start_with(ContactsCsvExporter::BOM))

        login(other_user)
        importar(exportado)

        expect(other_user.contacts.order(:name).pluck(:name, :phone, :email, :address, :notes)).to(eq([
          ["Ana Silva", "(11) 98888-1234", "ana@exemplo.com", "Rua das Flores, 10", "Aniversário em 10/05"],
          ["Contato de Outro", "(11) 96666-1234", nil, nil, nil],
          ["João Coração", "(11) 97777-1234", nil, nil, nil],
        ]))
      end
    end

    context "arquivo com linhas inválidas" do
      before { login(user) }

      it "importa as linhas válidas e aponta linha e campo do erro (Cenário 3)" do
        importar(
          "#{headers}\nAna Silva,(11) 98888-1234\nBruno Costa,(11) 97777-1234\nCarla Dias,12345\n",
        )

        expect(response).to(have_http_status(:unprocessable_entity))
        expect(response.body).to(include("Linha 4: telefone inválido. Use o formato (XX) XXXXX-XXXX."))
        expect(user.contacts.pluck(:name)).to(eq(["Ana Silva", "Bruno Costa"]))
      end

      it "resume quantas linhas entraram e mostra a listagem de contatos" do
        create_contact(user, name: "Contato existente", phone: "(11) 95555-1234")

        importar("#{headers}\nAna Silva,(11) 98888-1234\nCarla Dias,12345\n")

        expect(response.body).to(include("1 de 2 linhas entraram. Veja o que ficou de fora."))
        expect(response.body).to(include("Contato existente"))
      end

      it "trata telefone já cadastrado como erro e preserva o contato existente (RN01/RN02)" do
        create_contact(user, name: "Ana Original", phone: "(11) 98888-1234")

        importar("#{headers}\nAna Nova,(11) 98888-1234\n")

        expect(response).to(have_http_status(:unprocessable_entity))
        expect(response.body).to(include("Linha 2: telefone já cadastrado"))
        expect(user.contacts.sole.name).to(eq("Ana Original"))
      end
    end

    context "arquivo recusado" do
      before { login(user) }

      it "recusa arquivo acima do limite de 5 MB (Cenário 4 — o caso de 50 MB)" do
        post(
          importar_contacts_path,
          params: { arquivo: oversized_upload },
        )

        expect(flash[:alert]).to(eq("Arquivo muito grande: o limite é de 5 MB."))
        expect(user.contacts.count).to(eq(0))
      end

      it "recusa arquivo sem as colunas obrigatórias" do
        importar("telefone,e-mail\n(11) 98888-1234,x@y.com\n")

        expect(flash[:alert]).to(eq("O arquivo precisa ter as colunas: nome."))
        expect(user.contacts.count).to(eq(0))
      end

      it "recusa arquivo vazio" do
        importar("")

        expect(flash[:alert]).to(eq("O arquivo está vazio."))
      end

      it "avisa quando nenhum arquivo foi escolhido" do
        post(importar_contacts_path)

        expect(flash[:alert]).to(eq("Selecione um arquivo CSV para importar."))
        expect(user.contacts.count).to(eq(0))
      end
    end
  end

  # Arquivo real acima do limite — sem stub, é o mesmo caminho do upload de 50 MB.
  def oversized_upload
    file = Tempfile.new(["contatos", ".csv"])
    file.write("nome,telefone\n")
    file.write("a" * (5.megabytes + 1))
    file.rewind

    Rack::Test::UploadedFile.new(file.path, "text/csv")
  end
end
