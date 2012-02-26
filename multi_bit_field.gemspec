$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "multi_bit_field/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "multi_bit_field"
  s.version     = MultiBitField::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of MultiBitField."
  s.description = "TODO: Description of MultiBitField."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.1"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "minitest"
end
