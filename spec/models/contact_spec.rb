# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Contact, type: :model) do
  describe "associations" do
    it { is_expected.to(belong_to(:user)) }
  end

  describe "validations" do
    it { is_expected.to(validate_presence_of(:name)) }
    it { is_expected.to(validate_length_of(:name).is_at_most(50)) }
    it { is_expected.to(validate_presence_of(:phone)) }
  end

  describe "phone" do
    it "rejeita formato inválido" do
      contact = described_class.new(user: create_user, name: "Ana", phone: "123")
      expect(contact).not_to(be_valid)
    end

    it "aceita formato brasileiro válido" do
      contact = described_class.new(user: create_user, name: "Ana", phone: "(11) 98888-1234")
      expect(contact).to(be_valid)
    end

    it "é único por usuário" do
      user = create_user
      create_contact(user, phone: "(11) 98888-1234")

      duplicate = described_class.new(user: user, name: "Outro", phone: "(11) 98888-1234")
      expect(duplicate).not_to(be_valid)
    end

    it "permite o mesmo telefone entre usuários diferentes" do
      first = create_contact(create_user, phone: "(11) 98888-1234")
      second = described_class.new(user: create_user, name: "Outro", phone: "(11) 98888-1234")

      expect(first.user_id).not_to(eq(second.user_id))
      expect(second).to(be_valid)
    end
  end

  describe "email" do
    it "é opcional" do
      contact = described_class.new(user: create_user, name: "Ana", phone: "(11) 98888-1234")
      expect(contact).to(be_valid)
    end

    it "aceita formato válido" do
      contact = described_class.new(
        user: create_user, name: "Ana", phone: "(11) 98888-1234", email: "ana@exemplo.com",
      )
      expect(contact).to(be_valid)
    end

    it "rejeita formato inválido" do
      contact = described_class.new(
        user: create_user, name: "Ana", phone: "(11) 98888-1234", email: "email-sem-arroba",
      )
      expect(contact).not_to(be_valid)
      expect(contact.errors[:email]).to(include("inválido."))
    end
  end

  describe "campos extras (address/notes)" do
    it "aceita endereço dentro do limite" do
      contact = described_class.new(
        user: create_user,
        name: "Ana",
        phone: "(11) 98888-1234",
        address: "Rua X, 100",
        notes: "Trabalho",
      )
      expect(contact).to(be_valid)
    end

    it "rejeita endereço acima de 255 caracteres" do
      contact = described_class.new(
        user: create_user, name: "Ana", phone: "(11) 98888-1234", address: "a" * 256,
      )
      expect(contact).not_to(be_valid)
      expect(contact.errors[:address]).to(include("Muito grande. Máximo de 255 caracteres"))
    end

    it "rejeita notas acima de 1000 caracteres" do
      contact = described_class.new(
        user: create_user, name: "Ana", phone: "(11) 98888-1234", notes: "a" * 1001,
      )
      expect(contact).not_to(be_valid)
      expect(contact.errors[:notes]).to(include("Muito grande. Máximo de 1000 caracteres"))
    end
  end

  describe ".search" do
    it "busca por nome" do
      user = create_user
      create_contact(user, name: "Ana Silva", phone: "(11) 98888-1234")

      expect(described_class.search("Silva")).to(include(Contact.find_by(name: "Ana Silva")))
    end

    it "busca por telefone" do
      user = create_user
      create_contact(user, name: "Ana Silva", phone: "(11) 98888-1234")

      expect(described_class.search("98888")).to(include(Contact.find_by(name: "Ana Silva")))
    end

    context "com accents (US07)" do
      it "acha o contato sem digitar o acento" do
        user = create_user
        create_contact(user, name: "João Silva")

        expect(described_class.search("joao")).to(include(Contact.find_by(name: "João Silva")))
      end

      it "acha o contato digitando o acento quando o dado não tem" do
        user = create_user
        create_contact(user, name: "Joao Silva")

        expect(described_class.search("João")).to(include(Contact.find_by(name: "Joao Silva")))
      end

      it "ignora a caixa em ambas as direções" do
        user = create_user
        create_contact(user, name: "joão silva")

        expect(described_class.search("JOÃO")).to(include(Contact.find_by(name: "joão silva")))
      end

      it "busca por e-mail com acento" do
        user = create_user
        create_contact(user, name: "Ana", email: "contato@mariao.com.br")

        expect(described_class.search("mariao")).to(include(Contact.find_by(name: "Ana")))
      end

      it "acha por palavra no meio do nome" do
        user = create_user
        create_contact(user, name: "João Silva Santos")

        expect(described_class.search("Silva")).to(include(Contact.find_by(name: "João Silva Santos")))
      end
    end

    context "com erro de digitação (pg_trgm)" do
      it "acha com um caractere trocado" do
        user = create_user
        create_contact(user, name: "Pedro Lima")

        expect(described_class.search("pedri")).to(include(Contact.find_by(name: "Pedro Lima")))
      end

      it "acha no plural" do
        user = create_user
        create_contact(user, name: "João Silva")

        expect(described_class.search("joaos")).to(include(Contact.find_by(name: "João Silva")))
      end

      it "não arrasta contato que só tem palavra parecida" do
        user = create_user
        create_contact(user, name: "Joana Prado")
        create_contact(user, name: "Pedro Lima")

        # "ana" é vizinha de "Joana" e "pedri" de "Pedro": a busca por um não
        # pode devolver o outro.
        expect(described_class.search("ana")).not_to(include(Contact.find_by(name: "Pedro Lima")))
        expect(described_class.search("pedri")).not_to(include(Contact.find_by(name: "Joana Prado")))
      end
    end

    context "termos degenerados" do
      it "não devolve nada para termo vazio ou só com espaços" do
        user = create_user
        create_contact(user, name: "Ana Silva")

        expect(described_class.search("")).to(be_empty)
        expect(described_class.search("   ")).to(be_empty)
        expect(described_class.search(nil)).to(be_empty)
      end

      it "não traz contato sem e-mail ao buscar por e-mail" do
        user = create_user
        create_contact(user, name: "Ana Silva")

        expect(described_class.search("exemplo.com")).to(be_empty)
      end
    end

    it "não vaza contato de outra conta" do
      ana = create_user
      bruno = create_user
      create_contact(ana, name: "Silvia Zouza", phone: "(11) 90000-0001")
      create_contact(bruno, name: "Carlos Pradp", phone: "(11) 90000-0002")

      expect(ana.contacts.search("pradp")).to(be_empty)
      expect(ana.contacts.search("zouza")).to(include(Contact.find_by(name: "Silvia Zouza")))
    end

    it "não varre a tabela inteira: o recorte por user_id usa índice" do
      user = create_user
      create_contact(user, name: "Ana Silva")

      # `unaccent` é STABLE, não IMMUTABLE, então não pode entrar em índice de
      # expressão. O que segura a consulta é o índice de user_id. Desligar o
      # seq scan tira o tamanho da tabela da decisão: se o índice não servisse,
      # o planner seria forçado a varrer de qualquer forma e a spec quebraria.
      described_class.connection.execute("SET LOCAL enable_seqscan = off")
      plan = described_class.connection
        .select_values("EXPLAIN #{user.contacts.search("Silva").to_sql}")
        .join(" ")

      expect(plan).to(match(/Index Scan/))
      expect(plan).not_to(match(/Seq Scan/))
    end
  end
end
