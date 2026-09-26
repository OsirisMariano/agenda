# frozen_string_literal: true

require "rails_helper"

RSpec.describe("Exportação de contatos", type: :request) do
  let(:user) { create_user }
  let(:other_user) { create_user }

  def login(usuario)
    post(entrar_path, params: { email: usuario.email, password: "123456" })
  end

  # Linhas do CSV da resposta, já sem o BOM.
  def csv_rows
    CSV.parse(response.body.delete_prefix(ContactsCsvExporter::BOM))
  end

  describe "GET /contacts/exportar" do
    context "sem autenticação" do
      it "redireciona para o login" do
        create_contact(user, name: "Ana Silva")

        get exportar_contacts_path

        expect(response).to(redirect_to(entrar_url))
      end
    end

    context "autenticado" do
      before { login(user) }

      it "responde com o tipo text/csv em UTF-8" do
        get exportar_contacts_path

        expect(response).to(have_http_status(:success))
        expect(response.media_type).to(eq("text/csv"))
        expect(response.charset).to(match(/UTF-8/i))
      end

      it "envia o arquivo como anexo com nome datado" do
        get exportar_contacts_path

        expect(response.headers["Content-Disposition"]).to(
          match(/attachment; filename="contatos-\d{4}-\d{2}-\d{2}\.csv"/),
        )
      end

      it "exporta todos os contatos do usuário logado e nenhum de outro usuário" do
        create_contact(user, name: "Ana Silva")
        create_contact(user, name: "Bruno Costa")
        create_contact(other_user, name: "Contato de Outro")

        get exportar_contacts_path

        expect(csv_rows.drop(1).map(&:first)).to(eq(["Ana Silva", "Bruno Costa"]))
      end

      it "ordena as linhas por nome" do
        create_contact(user, name: "Zilda")
        create_contact(user, name: "Ana")
        create_contact(user, name: "Marcos")

        get exportar_contacts_path

        expect(csv_rows.drop(1).map(&:first)).to(eq(["Ana", "Marcos", "Zilda"]))
      end

      it "exporta todos os contatos, ignorando o limite de 12 por página" do
        15.times { |i| create_contact(user, name: "Contato #{format("%02d", i)}") }

        get exportar_contacts_path

        expect(csv_rows.size).to(eq(16)) # 15 contatos + cabeçalho
      end

      it "exporta apenas o cabeçalho quando o usuário não tem contatos" do
        get exportar_contacts_path

        expect(csv_rows).to(eq([["nome", "telefone", "e-mail", "endereço", "notas"]]))
      end

      it "inclui o BOM UTF-8 no corpo da resposta" do
        create_contact(user, name: "João Coração")

        get exportar_contacts_path

        expect(response.body).to(start_with(ContactsCsvExporter::BOM))
      end

      it "mantém os acentos intactos no corpo da resposta" do
        create_contact(user, name: "João Coração", address: "Av. São João, 100")

        get exportar_contacts_path

        expect(response.body).to(include("João Coração", "Av. São João, 100"))
      end
    end
  end
end
