# TTY::Testing

> A testing tool for interactive command line apps

**TTY::Testing** provides testing component for [TTY](https://github.com/piotrmurach/tty) toolkit.

## Features

* Easy and intuitive DSL for testing interactive command line apps
* Various tools for output inspection
* Feeding the input right when it is expected, not in a test setup
* Runs your app in the same process and in the same thread

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tty-testing'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tty-testing

## Contents

* [1. Basic usage](#1-basic-usage)
* [2. Pausing on input]
  * [2.1 Implicit pausing and resuming]
    * [2.1.1 Pre-populated input]
  * [2.2 Explicit pausing and resuming]
* [3. Output inspection]
  * [3.1 ]
* [4. Misc and aux]
  * [4.1 run!]
  * [4.2 exited?]
* [5. Examples](#5-examples)
  * [5.1 Using with the rest of TTY Toolkit family]
* [6. How it works]

## 1. Basic usage

`TTT::Testing` wraps your console application into a testable object
and provides testable standard IO streams.

```ruby
require "tty/testing"

app = TTY::Testing.app_wrapper do |input, output|
  output.puts "What is your name?"
  name = input.gets
  output.puts "Hello, #{name.strip}!"
end

app.run!

app.output # What is your name?
app.input.puts "John"
app.output # Hello, John!
```

In real-world settings it would look similar to this:

```ruby
require "tty/prompt"

RSpec.describe "my console app" do
  let(:app) do
    TTY::Testing.app_wrapper do |input, output|
      prompt = TTY::Prompt.new(enable_color: false, input: input, output: output) # Note test streams have been passed

      prompt.yes?("Do you like Ruby?")

      prompt.collect do
        key(:name).ask("Name?")
        key(:age).ask("Age?")
      end

      # ...app goes on
    end
  end

  before { app.run! }

  it "asks a series of questions" do
    expect(app.output).to end_with "Do you like Ruby? (Y/n) "
    app.input.puts "y"

    expect(app.output).to end_with "Name? "
    app.input.puts "John"

    expect(app.output).to end_with "Age? "
    app.input.puts "22"

    # ...tests go on
  end
end
```

See [examples](#5-examples) for more colourful usage samples.
