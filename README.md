# CatarseMercadopagos

Mercadopagos integration with [Catarse](http://github.com/carloshlopez/catarse) crowdfunding platform

## Installation

Add this lines to your Catarse application's Gemfile:

    gem 'mercadopagos', git: 'git://github.com/carloshlopez/mercadopagos.git'
    gem 'catarse_mercadopagos', git: 'git://github.com/carloshlopez/mercadopagos.git'

And then execute:

    $ bundle

## Usage

Configure the routes for your Catarse application. Add the following lines in the routes file (config/routes.rb):

    mount CatarseMercadopagos::Engine => "/", :as => "catarse_mercadopagos"

### Configurations

Create this configurations into Catarse database:

In Rails console, run this:

    Configuration.create!(name: "mercadopagos_client_secret", value: "111111") 
    Configuration.create!(name: "mercadopagos_client_id", value: "sdf4fs34442")

  Currencies:
    "COP" -> default
    "ars"
    "mxn"
    "clp"
    "brl"
    "usd"

## Development environment setup

Clone the repository:

    $ git clone git://github.com/carloshlopez/catarse_mercadopagos.git

Add the catarse code into test/dummy:

    $ git submodule add git://github.com/carloshlopez/catarse.git test/dummy

Copy the Catarse's gems to Gemfile:

    $ cat test/dummy/Gemfile >> Gemfile

And then execute:

    $ bundle

Replace the content of test/dummy/config/boot.rb by this:

    require 'rubygems'
    gemfile = File.expand_path('../../../../Gemfile', __FILE__)
    if File.exist?(gemfile)
      ENV['BUNDLE_GEMFILE'] = gemfile
      require 'bundler'
      Bundler.setup
    end
    YAML::ENGINE.yamler= 'syck' if defined?(YAML::ENGINE)

    $:.unshift File.expand_path('../../../../lib', __FILE__)


## Troubleshooting in development environment

Remove the admin folder from test/dummy application to prevent a weird active admin bug:

    $ rm -rf test/dummy/app/admin

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


This project rocks and uses MIT-LICENSE.

# catarse_mercadopagos
Catarse payment engine for mercado pagos

