# frozen_string_literal: true

# Navegação da área admin (casca). Os itens são declarativos para manter a
# sidebar e o breadcrumb consistentes e o destaque do item ativo em um só lugar.
module AdminHelper
  def admin_nav_items
    [
      { label: "Visão Geral", path: admin_path, icon: "bi-speedometer2" },
      { label: "Usuários", path: usuarios_path, icon: "bi-people" },
    ]
  end

  def admin_nav_item(label, path, icon: nil)
    classes = ["admin-nav-link"]
    classes << "active" if current_page?(path)

    content_tag(:li, class: "admin-nav-item") do
      link_to(path, class: classes.join(" ")) do
        safe_join([
          (content_tag(:i, "", class: "bi #{icon} admin-nav-icon") if icon),
          content_tag(:span, label),
        ].compact)
      end
    end
  end

  def admin_breadcrumb(*items)
    content_tag(:ol, class: "breadcrumb mb-0") do
      safe_join(items.each_with_index.map do |(label, path), index|
        last = index == items.length - 1
        classes = ["breadcrumb-item"]
        classes << "active" if last

        content_tag(:li, class: classes.join(" "), "aria-current": (last ? "page" : nil)) do
          last ? label : link_to(label, path)
        end
      end)
    end
  end
end
