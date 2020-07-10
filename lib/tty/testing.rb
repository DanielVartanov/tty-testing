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

        self.entire_stdout = String.new
        self.entire_stderr = String.new

        self.paused = true
        self.fiber = Fiber.new do
          app_block.call(stdin_reader, stdout_writer, stderr_writer)
          self.exited = true
        end

        entangle_fiber_and_stdin(fiber, stdin_reader, stdin_writer)

        self.exited = false
      end

      def stdout
        stdout_reader.read_available.tap do |output_chunk|
          @entire_stdout << output_chunk
        end
      end

      def stderr
        stderr_reader.read_available.tap do |output_chunk|
          @entire_stderr << output_chunk
        end
      end

      def entire_stdout
        stdout
        @entire_stdout
      end

      def entire_stderr
        stderr
        @entire_stderr
      end

      alias output stdout
      alias entire_output entire_stdout

      def input
        stdin_writer
      end

      def pause!
        self.paused = true
      end

      def resume!
        self.paused = false
        fiber.resume
      end
      alias run! resume!

      attr_reader :exited
      alias exited? exited

      protected

      attr_accessor :stdin_reader, :stdin_writer
      attr_accessor :stdout_reader, :stdout_writer
      attr_accessor :stderr_reader, :stderr_writer

      attr_writer :entire_stdout, :entire_stderr

      attr_accessor :fiber

      attr_accessor :paused
      alias paused? paused

      attr_writer :exited

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
