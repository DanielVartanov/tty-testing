# frozen_string_literal: true

require "stringio"
require "io/wait"

require_relative "../io/wait/read_available"
require_relative "testing/app"

module TTY
  module Testing
    module_function

    def app_wrapper(&block)
      App.new(&block)
    end
  end
end
