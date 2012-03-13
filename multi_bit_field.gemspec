$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "multi_bit_field/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "multi_bit_field"
  s.version     = MultiBitField::VERSION
  s.authors     = ["Aaron Spiegel"]
  s.email       = ["spiegela@gmail.com"]
  s.summary     = "Add support for multiple, and varied sized bitfields to Active Record."
  s.description = ""

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.markdown"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.1"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "minitest"
  s.add_development_dependency "pry"
end
