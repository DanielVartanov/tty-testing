# frozen_string_literal: true

RSpec.describe TTY::Testing::App, "#exited?" do
  let(:app) do
    TTY::Testing.app_wrapper do |input, _|
      input.gets
    end
  end

  subject { app.exited? }

  context "before the start of the program" do
    it { is_expected.to be_falsey }

    context "in the middle of execution" do
      before { app.run! }

      it { is_expected.to be_falsey }

      context "after the end of the program" do
        before { app.input.puts }

        it { is_expected.to be_truthy }
      end
    end
  end
end
