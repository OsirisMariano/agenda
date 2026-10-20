# frozen_string_literal: true

# Agrega os números exibidos na área admin existente (`GET /usuarios`).
#
# Somente leitura: não persiste nada e nenhum dado de contato individual sai
# daqui — apenas contagens. A série semanal sempre tem 8 pontos (semanas
# naturais de segunda a domingo, terminando na semana corrente, ainda que
# parcial) e semanas sem criação entram como zero, preenchidas em Ruby porque
# `GROUP BY` não cria linha para período vazio.
class AdminMetrics
  WEEKS = 8

  # Total de contas do sistema.
  def users_count
    @users_count ||= User.count
  end

  # Total de contatos de todos os usuários (visão global de admin).
  def contacts_count
    @contacts_count ||= Contact.count
  end

  # Array com exatamente `WEEKS` pontos, do mais antigo ao mais recente.
  # Cada ponto é `{ label: "dd/mm–dd/mm", total: Integer }`.
  def weekly_contacts
    @weekly_contacts ||= build_weekly_contacts
  end

  # Maior total da série — escala das barras. Zero quando não há dados.
  def max_weekly_total
    @max_weekly_total ||= weekly_contacts.map { |week| week[:total] }.max || 0
  end

  private

  def build_weekly_contacts
    this_week_start = Date.current.beginning_of_week
    counts = contacts_per_week_start

    Array.new(WEEKS) do |offset|
      week_start = this_week_start - (WEEKS - 1 - offset).weeks
      {
        label: "#{week_start.strftime("%d/%m")}–#{(week_start + 6.days).strftime("%d/%m")}",
        total: counts.fetch(week_start, 0),
      }
    end
  end

  # Hash { Date (segunda-feira) => total }, restrito à janela das 8 semanas.
  def contacts_per_week_start
    window_start = (Date.current.beginning_of_week - (WEEKS - 1).weeks).beginning_of_day

    rows = Contact
      .where("contacts.created_at >= ?", window_start)
      .group("date_trunc('week', contacts.created_at)")
      .count

    rows.each_with_object({}) do |(week_start, total), hash|
      hash[week_start.to_date] = total
    end
  end
end
