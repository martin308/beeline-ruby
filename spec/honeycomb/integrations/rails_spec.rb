# frozen_string_literal: true

require "logger"
require "rack/test"
require "rails"
require "action_controller/railtie"

RSpec.describe Honeycomb::Rack do
  include Rack::Test::Methods

  let(:libhoney_client) { Libhoney::TestClient.new }
  let(:app) do
    Class.new(Rails::Application).tap do |app|
      app.config.logger = Logger.new(STDERR)
      app.config.log_level = :fatal
      app.config.eager_load = false
      app.config.honeycomb.client = libhoney_client
      app.config.secret_key_base = "3b7cd727ee24e8444053437c36cc66c4"
      app.initialize!

      app.routes.draw do
        get "/hello/:name" => "test#hello"
      end
    end
  end

  class TestController < ActionController::Base
    def hello
      render plain: "Hello World!"
    end
  end

  before do
    header("Http-Version", "HTTP/1.0")
    header("User-Agent", "RackSpec")

    get "/hello/martin"
  end

  it "returns ok" do
    expect(last_response).to be_ok
  end

  it "sends the right number of events" do
    expect(libhoney_client.events.size).to eq 3
  end

  let(:event_data) { libhoney_client.events.map(&:data) }

  # only the root span will have package_fields so don't require them
  it_behaves_like "event data", package_fields: false
end
