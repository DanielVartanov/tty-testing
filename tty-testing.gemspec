require_relative 'lib/tty/testing/version'

Gem::Specification.new do |spec|
  spec.name          = "tty-testing"
  spec.version       = TTY::Testing::VERSION
  spec.authors       = ["Daniel Vartanov", "Piotr Murach"].sort
  spec.email         = ["piotr@piotrmurach.com"]

  spec.summary       = %q{Testing tool for interactive command line apps}
  spec.description   = spec.summary
  spec.homepage      = "https://piotrmurach.github.io/tty"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  if spec.respond_to?(:metadata=)
    spec.metadata = {
      "allowed_push_host" => "https://rubygems.org",
      "bug_tracker_uri"   => "https://github.com/piotrmurach/tty-testing/issues",
      "changelog_uri"     => "https://github.com/piotrmurach/tty-testing/blob/master/CHANGELOG.md",
      "documentation_uri" => "https://www.rubydoc.info/gems/tty-testing",
      "homepage_uri"      => spec.homepage,
      "source_code_uri"   => "https://github.com/piotrmurach/tty-testing"
    }
  end

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.extra_rdoc_files = ["README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
end
