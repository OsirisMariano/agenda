# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :require_admin

  def index
    @metrics = AdminMetrics.new
  end
end
