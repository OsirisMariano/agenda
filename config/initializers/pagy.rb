# frozen_string_literal: true

require "pagy/extras/bootstrap"
require "pagy/extras/overflow"

Pagy::DEFAULT[:limit] = 12
Pagy::DEFAULT[:overflow] = :last_page
