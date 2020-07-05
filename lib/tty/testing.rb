# frozen_string_literal: true

require "stringio"
require "io/wait"
require_relative "../io/wait/read_available"

module TTY
  module Testing
    class App
      def initialize(&app_block)
        self.stdin_reader, self.stdin_writer = IO.pipe
        self.stdout_reader, self.stdout_writer = IO.pipe
        self.stderr_reader, self.stderr_writer = IO.pipe

        self.paused = true
        self.fiber = Fiber.new { app_block.call(stdin_reader, stdout_writer, stderr_writer) }

        entangle_fiber_and_stdin(fiber, stdin_reader, stdin_writer)
      end

      def stdout
        stdout_reader.read_available
      end
      alias output stdout

      def stderr
        stderr_reader.read_available
      end

      def input
        stdin_writer
      end

      def run!
        self.paused = false
        fiber.resume
      end

      protected

      attr_accessor :stdin_reader, :stdin_writer
      attr_accessor :stdout_reader, :stdout_writer
      attr_accessor :stderr_reader, :stderr_writer

      attr_accessor :fiber

      attr_accessor :paused
      alias paused? paused

      def entangle_fiber_and_stdin(fiber, stdin_reader, stdin_writer)
        def stdin_reader.gets
          if ready?
            super
          else
            Fiber.yield
            super
          end
        end

        paused_proc = self.method(:paused?).to_proc
        stdin_writer.define_singleton_method(:puts) do |*args|
          super(*args)
          fiber.resume unless paused_proc.()
        end
      end
    end

    module_function

    def app_wrapper(&block)
      App.new(&block)
    end
  end
end
