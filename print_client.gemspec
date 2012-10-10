# -*- encoding: utf-8 -*-
require File.expand_path('../lib/print_client/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Hector Sansores', 'Leopoldo Ramírez del Prado']
  gem.email         = ['hector.sansores@virtus.com.mx', 'leopoldo.ramirez@virtus.com.mx']
  gem.description   = 'Downloads labels from virtusprinter server and sends them to a serial printer'
  gem.summary       = 'Print client for virtusprinter'
  gem.homepage      = 'http://rubygems.org/gems/printclient'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "print_client"
  gem.require_paths = ["lib"]
  gem.version       = PrintClient::VERSION
  gem.add_runtime_dependency 'virtusprinter', ['0.2.0.beta1']
  gem.add_runtime_dependency 'serialport', ['1.1.0']
  gem.add_runtime_dependency 'nokogiri', ['1.5.5']
end
