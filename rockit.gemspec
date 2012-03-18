# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rockit/version"

Gem::Specification.new do |s|
  s.name        = "rockit"
  s.version     = Rockit::VERSION
  s.authors     = ["Ben Willis"]
  s.email       = ["benjamin.willis@gmail.com"]
  s.homepage    = "https://github.com/bwillis/rockit"
  s.summary     = %q{Rockit is a way to manage your external dependencies and keep your environment up to date.}
  s.description = %q{Check and verify external project and rails specific project dependencies. The script will cache results to ensure quick script execution each time.}

  s.rubyforge_project = "rockit"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec"
  s.add_development_dependency "mocha"
end
