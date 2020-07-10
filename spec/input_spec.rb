# frozen_string_literal: true

RSpec.describe TTY::Testing::App, "#input" do
  describe "pre-populated input" do
    let(:app) do
      TTY::Testing.app_wrapper do |input, output|
        output.puts "What is your name?"
        name = input.gets
        output.puts "Hello, #{name.strip}!"
      end
    end

    context "when input is pre-populated" do
      before do
        app.input.puts "Motaro"
        app.run!
      end

      it "does not pause and passes input to the program" do
        expect(app.output).to eq "What is your name?\n" \
                                 "Hello, Motaro!\n"
      end
    end
  end

  describe "pausing and resuming" do
    let(:accumulator) { Array.new }

    let(:app) do
      TTY::Testing.app_wrapper do |input, _|
        accumulator << :beginning
        name = input.gets
        accumulator << name.strip
      end
    end

    before { app.run! }

    it 'automatically pauses execution when expects input' do
      expect(accumulator).to eq [:beginning]
    end

    describe 'implicit resuming' do
      context 'when a line of input is passed' do
        before { app.input.puts "Motaro" }

        it 'automatically resumes execution' do
          expect(accumulator).to eq [:beginning, "Motaro"]
        end
      end
    end

    describe 'explicit resuming' do
      context 'whe the app is explicitly paused' do
        before { app.pause! }

        context 'when a line of input is passed' do
          before { app.input.puts "Motaro" }

          it 'does not resume execution' do
            expect(accumulator).to eq [:beginning]
          end

          context 'when the app is explicitly resumed' do
            before { app.resume! }

            it 'resumes execution' do
              expect(accumulator).to eq [:beginning, "Motaro"]
            end
          end
        end
      end
    end
  end
end
