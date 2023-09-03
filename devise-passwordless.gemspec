
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "devise/passwordless/version"

Gem::Specification.new do |spec|
  spec.name          = "devise-passwordless"
  spec.version       = Devise::Passwordless::VERSION
  spec.authors       = ["Abe Voelker"]
  spec.email         = ["_@abevoelker.com"]

  spec.summary       = %q{Passwordless (email-only) login strategy for Devise}
  #spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = "https://github.com/abevoelker/devise-passwordless"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    #spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = spec.homepage
    #spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.1.0"

  spec.add_dependency "devise"
  spec.add_dependency "globalid"
  spec.add_development_dependency "timecop"

  spec.post_install_message = %q{
  Devise Passwordless v1.0 introduces major, backwards-incompatible changes!
  Please see https://github.com/abevoelker/devise-passwordless/blob/master/UPGRADING.md
  for a guide on upgrading, or CHANGELOG.md for a list of changes.
  }
end
