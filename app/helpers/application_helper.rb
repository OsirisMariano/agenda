# frozen_string_literal: true

module ApplicationHelper
  def form_field_error(f, attribute)
    return unless f.object.errors[attribute].any?

    content_tag(:div, f.object.errors[attribute].join(", "), class: "invalid-feedback d-block")
  end

  def form_field_class(f, attribute)
    f.object.errors[attribute].any? ? "form-control is-invalid" : "form-control"
  end
end
