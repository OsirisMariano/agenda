# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  def form_field_error(f, attribute)
    return if f.object.errors[attribute].none?

    content_tag(:div, f.object.errors[attribute].join(", "), class: "invalid-feedback d-block")
  end

  def form_field_class(f, attribute)
    f.object.errors[attribute].any? ? "form-control is-invalid" : "form-control"
  end
end
