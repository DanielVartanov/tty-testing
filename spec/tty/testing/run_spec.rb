# frozen_string_literal: true

require "tty/testing"

RSpec.describe TTY::Testing::App, "#run!" do
  let(:app) do
    TTY::Testing.app_wrapper do |_, output|
      output.puts "Hello, world!"
    end
  end

  context "before `#run!` is called" do
    it "does not execute the application" do
      expect(app.output).to be_empty
    end

    context "when `#run!` is called" do
      before { app.run! }

      it "executes the application" do
        expect(app.output).to eq "Hello, world!\n"
      end
    end
  end
end
