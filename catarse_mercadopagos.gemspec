$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "catarse_mercadopagos/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "catarse_mercadopagos"
  s.version     = CatarseMercadopagos::VERSION
  s.authors     = ["Carlos Lopez"]
  s.email       = ["carloshlopez@gmail.com"]
  s.homepage    = "http://github.com/carloshlopez/catarse_mercadopagos"
  s.summary     = "mercadopagos integration with Catarse"
  s.description = "Mercadopagos integration with Catarse crowdfunding platform"

  s.files         = `git ls-files`.split($\)
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})

  s.add_dependency "rails"
  s.add_dependency "mercadopago-sdk"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "fakeweb"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "database_cleaner"
end
