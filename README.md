<div align="center">
  <a href="https://piotrmurach.github.io/tty" target="_blank"><img width="130" src="https://cdn.rawgit.com/piotrmurach/tty/master/images/tty.png" alt="tty logo" /></a>
</div>

# TTY::Testing [![Gitter](https://badges.gitter.im/Join%20Chat.svg)][gitter]

[gitter]: https://gitter.im/piotrmurach/tty

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
* [2. Pausing on input](#2-pausing-on-input)
  * [2.1 Implicit pausing and resuming](#2-1-implicit-pausing-and-resuming)
    * [2.1.1 Pre-populated input](#2-1-1-pre-populated-input)
  * [2.2 Explicit pausing and resuming](#2-2-explicit-pausing-and-resuming)
* [3. Output inspection](#3-output-inspection)
  * [3.1 #output](#3-1-output)
  * [3.2 #entire_output](#3-2-entire_output)
  * [3.3 #output_stream](#3-3-output_stream)
  * [3.4 Separation of stdout and stderr](#3-4-separation-of-stdout-and-stderr)
* [4. Misc and aux]
  * [4.1 #run!]
  * [4.2 #exited?]
* [5. Examples]
  * [5.1 Using with the rest of TTY Toolkit family]
* [6. How it works](#6-how-it-works)

## 1. Basic usage

`TTT::Testing.app_wrapper` wraps your console application into a testable object
and provides testable standard IO streams.

```ruby
require "tty/testing"

app = TTY::Testing.app_wrapper do |input, output|
  output.puts "What is your name?"
  name = input.gets
  output.puts "Hello, #{name.strip}!"
end

app.run!

app.output # => What is your name?
app.input.puts "John"
app.output # => Hello, John!
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


## 2. Pausing on input

Pausing execution of the app block is a crucial part of this gem and
is what makes it different from other CLI testing tools.

### 2.1 Implicit pausing and resuming

Whenever provided testable input stream receives `#gets`, `#readline`
or similar method calls it stops execution of the app and returns
flow control outside the app block.

Similarly, when app input stream receives data from the outside, app
block execution gets resumed.

```ruby
counter = 0

app = TTY::Testing.app_wrapper do |input, _|
  counter += 1
  input.gets
  counter += 100
end

app.run! # Execution of the app block will get paused on `input.gets`
puts counter # => 1

app.input.puts "hi there"
puts counter # => 101
```

#### 2.1.1 Pre-populated input

This is rarely useful but still possible:

```ruby
counter = 0

app = TTY::Testing.app_wrapper do |input, _|
  counter += 1
  input.gets
  counter += 100
end

app.input.puts "hi there" # Pre-pupulating the input
app.run!                  # Execution will not get paused on `input.gets`
puts counter # => 101
```

### 2.2 Explicit pausing and resuming

Sometimes it is useful be in full control over pausing and resuming of
the app block execution.

```ruby
counter = 0

app = TTY::Testing.app_wrapper do |input, _|
  counter += 1
  input.gets
  counter += 100
end

app.run!

app.pause!
app.input.puts "hi there" # Execution will not be resumed here
puts counter # => 1

app.resume!
puts counter # => 101
```

## 3. Output inspection

### 3.1 #output

`app.output` returns output written by the app _since the last
call of the same method_.

```ruby
app = TTY::Testing.app_wrapper do |input, output|
  output.puts "What is your name?"
  name = input.gets
  output.puts "Hello, #{name.strip}!"
end

app.run!
puts app.output # => What is your name?

app.input.puts "John"
puts app.output # => Hello, John!

# Nothing was written to the output since the last call to `app.output`
puts app.output # =>
```

### 3.2 #entire_output

`app.entire_output` returns entire output written by the app since the
beginning of its execution

```ruby
app = TTY::Testing.app_wrapper do |input, output|
  output.puts "What is your name?"
  name = input.gets
  output.puts "Hello, #{name.strip}!"
end

app.run!
app.output
app.input.puts "John"
app.output

puts app.entire_output
# =>
# What is your name?
# Hello, John!
```

### 3.3 #output_stream

`app.output_stream` is a genuine instance of `IO` which represent app
output.
Warning: reading or seeking the stream will affect return values of
`#output` and vice versa.

```ruby
app = TTY::Testing.app_wrapper do |_, output|
  output.puts "What is your name?"
  output.puts "Nevermind"
end

puts app.output_stream.ready?   # => false
app.run!
puts app.output_stream.ready?   # => true
puts app.output_stream.readline # => What is your name?
```

### 3.4 Separation of stdout and stderr

Standard output and standard error can be separated by accepting three
arguments in the app block:

```ruby
app = TTY::Testing.app_wrapper do |input, stdout, stderr|
  stderr.puts "[LOG] Execution started..."
  stdout.puts "What is your name?"
end

app.run!
puts app.stdout # => What is your name?
puts app.stderr # => [LOG] Execution started...
```

All correspondent methods like `#entire_stdout`, `#entire_stderr` and
`#stdout_stream`, `#stderr_stream` work as expected.


## 6. How it works

No additional processes or threads are spun, everything is done via
regular IO pipes and [Ruby Fibers](https://ruby-doc.org/core-2.7.1/Fiber.html)
