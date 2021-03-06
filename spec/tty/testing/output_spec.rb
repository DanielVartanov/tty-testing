# frozen_string_literal: true

RSpec.describe TTY::Testing::App, "output" do
  describe "separated stdout and stderr" do
    let(:app) do
      TTY::Testing.app_wrapper do |stdin, stdout, stderr|
        stderr.puts "[LOG] Program started"
        stdout.puts "What is your name?"
        stderr.puts "[LOG] Expecting input now..."

        name = stdin.gets # App will automatically pause here due to input expectation

        stdout.puts "Hello, #{name.strip}!"
        stderr.puts "[LOG] Exiting"
      end
    end

    before { app.run! }

    specify "#stdout returns only standard output" do
      expect(app.stdout).to eq "What is your name?\n"
    end

    specify "#stderr returns only standard error" do
      expect(app.stderr).to eq "[LOG] Program started\n" \
                               "[LOG] Expecting input now...\n"
    end

    context "after #stdout and #stderr were called" do
      before do
        app.stdout
        app.stderr
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
                                            "[LOG] Expecting input now...\n" \
                                            "[LOG] Exiting\n"
          end
        end

        describe "#stdout_stream, #stderr_stream" do
          it "returns respective IO stream" do
            expect(app.stdout_stream).to be_an(IO)
            expect(app.stdout_stream.readline).to eq "Hello, Kintaro!\n"

            expect(app.stderr_stream).to be_an(IO)
            expect(app.stderr_stream.readline).to eq "[LOG] Exiting\n"
          end
        end
      end
    end
  end

  describe "merged stdout and stderr" do
    let(:app) do
      TTY::Testing.app_wrapper do |input, output|
        output.puts "[LOG] Program started"
        output.puts "What is your name?"
        output.puts "[LOG] Expecting input now..."

        name = input.gets

        output.puts "Hello, #{name.strip}!"
        output.puts "[LOG] Exiting"
      end
    end

    before { app.run! }

    describe "#output" do
      it "merged stdout and stderr" do
        expect(app.output).to eq "[LOG] Program started\n" \
                                 "What is your name?\n" \
                                 "[LOG] Expecting input now...\n"

        app.input.puts "Kintaro"

        expect(app.output).to eq "Hello, Kintaro!\n" \
                                 "[LOG] Exiting\n"
      end
    end

    describe "#entire_output" do
      it "merged stdout and stderr" do
        expect(app.entire_output).to eq "[LOG] Program started\n" \
                                        "What is your name?\n" \
                                        "[LOG] Expecting input now...\n" \

        app.input.puts "Kintaro"

        expect(app.entire_output).to eq "[LOG] Program started\n" \
                                      "What is your name?\n" \
                                      "[LOG] Expecting input now...\n" \
                                      "Hello, Kintaro!\n" \
                                      "[LOG] Exiting\n"
      end
    end

    describe "#output_stream" do
      it "merged stdout and stderr" do
        expect(app.output_stream).to be_an(IO)

        expect(app.output_stream.read_available).to eq "[LOG] Program started\n" \
                                                       "What is your name?\n" \
                                                       "[LOG] Expecting input now...\n"

        app.input.puts "Kintaro"

        expect(app.output_stream.read_available).to eq "Hello, Kintaro!\n" \
                                                       "[LOG] Exiting\n"
      end
    end
  end

  describe "output of subprocesses" do
    let(:app) do
      TTY::Testing.app_wrapper do |_, output|
        pid = Process.spawn "echo 'Hello from subprocess!'", out: output
        Process.waitpid(pid)
      end
    end

    before { app.run! }

    it "captures output from subprocess" do
      expect(app.output).to eq "Hello from subprocess!\n"
    end
  end
end
