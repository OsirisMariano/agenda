# frozen_string_literal: true

require "rails_helper"

RSpec.describe(AdminMetrics) do
  subject(:metrics) { described_class.new }

  describe "#users_count" do
    it "conta todas as contas do sistema" do
      create_user
      create_user

      expect(metrics.users_count).to(eq(2))
    end

    it "retorna 0 quando não há usuários" do
      expect(metrics.users_count).to(eq(0))
    end
  end

  describe "#contacts_count" do
    it "conta os contatos de todos os usuários (visão global)" do
      user_a = create_user
      user_b = create_user
      create_contact(user_a)
      create_contact(user_a)
      create_contact(user_b)

      expect(metrics.contacts_count).to(eq(3))
    end

    it "retorna 0 quando não há contatos" do
      create_user

      expect(metrics.contacts_count).to(eq(0))
    end
  end

  describe "#weekly_contacts" do
    it "sempre devolve exatamente 8 pontos (INV-1)" do
      expect(metrics.weekly_contacts.length).to(eq(8))
    end

    it "devolve 8 pontos mesmo sem nenhum contato, todos zerados (SC-004)" do
      expect(metrics.weekly_contacts.map { |week| week[:total] }).to(all(eq(0)))
      expect(metrics.weekly_contacts.length).to(eq(8))
    end

    it "cada ponto tem rótulo e total, nunca nil (INV-4)" do
      metrics.weekly_contacts.each do |week|
        expect(week[:label]).to(be_present)
        expect(week[:total]).to(eq(0))
      end
    end

    it "conta o contato criado na semana corrente (último ponto)" do
      user = create_user
      create_contact(user)

      expect(metrics.weekly_contacts.last[:total]).to(eq(1))
      expect(metrics.weekly_contacts.first(7).sum { |week| week[:total] }).to(eq(0))
    end

    it "conta contato criado há 2 semanas no ponto correspondente, não no último" do
      user = create_user
      create_contact(user, created_at: 2.weeks.ago)

      weeks = metrics.weekly_contacts
      expect(weeks.last[:total]).to(eq(0))
      expect(weeks.sum { |week| week[:total] }).to(eq(1))
    end

    it "ignora contatos mais antigos que a janela de 8 semanas" do
      user = create_user
      create_contact(user, created_at: 9.weeks.ago)

      expect(metrics.weekly_contacts.sum { |week| week[:total] }).to(eq(0))
      expect(metrics.weekly_contacts.length).to(eq(8))
    end

    it "agrupa vários contatos da mesma semana em um único ponto" do
      user = create_user
      create_contact(user)
      create_contact(user)

      expect(metrics.weekly_contacts.last[:total]).to(eq(2))
    end

    it "mantém a ordem cronológica crescente, terminando na semana corrente (INV-5)" do
      labels = metrics.weekly_contacts.map { |week| week[:label] }
      expect(labels.uniq.length).to(eq(8))
      expect(metrics.weekly_contacts.length).to(eq(8))
    end

    it "soma da série nunca é maior que o total de contatos (INV-2)" do
      user = create_user
      create_contact(user)
      create_contact(user, created_at: 30.weeks.ago)

      total_na_serie = metrics.weekly_contacts.sum { |week| week[:total] }
      expect(total_na_serie).to(be <= metrics.contacts_count)
      expect(metrics.contacts_count).to(eq(2))
      expect(total_na_serie).to(eq(1))
    end
  end

  describe "#max_weekly_total" do
    it "retorna o maior total da série" do
      user = create_user
      create_contact(user)
      create_contact(user)

      expect(metrics.max_weekly_total).to(eq(2))
    end

    it "retorna 0 quando não há dados (barras vazias)" do
      expect(metrics.max_weekly_total).to(eq(0))
    end
  end
end
