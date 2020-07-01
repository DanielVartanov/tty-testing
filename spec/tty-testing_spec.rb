# frozen_string_literal: true

require "tty/testing"

RSpec.describe TTY::Testing::App do
  describe "app output inspection" do
    let(:app) do
      TTY::Testing.app_wrapper do |stdin, stdout, stderr|
        stderr.puts "[LOG] Program started"
        stdout.puts "What is your name?"
        stderr.puts "[LOG] Expecting input now..."

        name = stdin.gets # App will automatically pause here due to input expectation

        stdout.puts "Hello, #{name}!"
        stderr.puts "[LOG] Exiting"
      end
    end

    before { app.run! }

    specify "#stdout returns only standard output" do
      expect(app.stdout).to eq "What is your name?\n"
    end

    specify "#stderr returns only standard error" do
      expect(app.stderr).to eq "[LOG] Program started\n" \
                               "[LOG] Expecting input now..."
    end

    context "when nothing was written to the output since the last call" do
      specify "all output methods return empty string" do
        expect(app.stdout).to be_empty
        expect(app.stderr).to be_empty
      end
    end

    context "when app writes to the output again" do
      before { app.input.puts "Kintaro" } # App automatically resumes here due to a line of input

      describe "#stdout, #stderr" do
        it "returns respective output since the last call" do
          expect(app.stdout).to eq "Hello, Kintaro!\n"

          expect(app.stderr).to eq "[LOG] Exiting\n"
        end
      end

      describe "#entire_stdout, #entire_stderr" do
        it "returns respective output since the start of the program" do
          expect(app.entire_stdout).to eq "What is your name?\n" \
                                          "Hello, Kintaro!\n"

          expect(app.entire_stderr).to eq "[LOG] Program started\n" \
                                          "[LOG] Expecting input now..." \
                                          "[LOG] Exiting\n"
        end

        describe "#stdout_stream, #stderr_stream" do
          it "returns respective IO stream" do
            expect(app.stdout_stream).to be_an(IO)
            app.stdout_stream.rewind
            expect(app.stdout_stream.readlines.join).to eq "What is your name?\n" \
                                                           "Hello, Kintaro!\n"

            expect(app.stderr_stream).to be_an(IO)
            app.stderr_stream.rewind
            expect(app.stderr_stream.readlines.join).to eq "[LOG] Program started\n" \
                                                           "[LOG] Expecting input now..." \
                                                           "[LOG] Exiting\n"
          end
        end
      end
    end

    describe "stderr merged into stdout" do
      let(:app) do
        TTY::Testing.app_wrapper do |input, output|
          output.puts "[LOG] Program started"
          output.puts "What is your name?"
          output.puts "[LOG] Expecting input now..."

          name = stdin.gets

          output.puts "Hello, #{name}!"
          output.puts "[LOG] Exiting"
        end
      end

      before { app.run! }

      it "merges stdout and stderr" do
        expect(output).to eq "[LOG] Program started\n" \
                             "What is your name?\n" \
                             "[LOG] Expecting input now...\n"

        input.puts "Kintaro"

        expect(output).to eq "Hello, Kintaro!\n" \
                             "[LOG] Exiting"

        expect(app.entire_output).to eq "[LOG] Program started\n" \
                                          "What is your name?\n" \
                                          "[LOG] Expecting input now..." \
                                          "Hello, Kintaro!\n" \
                                          "[LOG] Exiting\n"

        expect(app.output_stream).to be_an(IO)
        app.output_stream.rewind
        expect(app.output_stream.readlines.join).to eq "[LOG] Program started\n" \
                                                       "What is your name?\n" \
                                                       "[LOG] Expecting input now..." \
                                                       "Hello, Kintaro!\n" \
                                                       "[LOG] Exiting\n"
      end
    end
  end

  describe '#run!' do
    let(:app) do
      TTY::Testing.app_wrapper do |_, output|
        output.puts 'Hello, world!'
      end
    end

    context 'before `#run!` is called' do
      it 'does not execute the application' do
        expect(app.output).to be_empty
      end

      context 'when `#run!` is called' do
        before { app.run! }

        it 'executes the application' do
          expect(app.output).to eq "Hello, world!\n"
        end
      end
    end
  end
end
