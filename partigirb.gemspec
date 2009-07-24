# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{partigirb}
  s.version = "0.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Alvaro Bautista", "Fernando Blat"]
  s.date = %q{2009-07-24}
  s.email = ["alvarobp@gmail.com", "ferblape@gmail.com"]
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "lib/partigirb.rb",
     "lib/partigirb/client.rb",
     "lib/partigirb/core_ext.rb",
     "lib/partigirb/handlers/atom_handler.rb",
     "lib/partigirb/handlers/json_handler.rb",
     "lib/partigirb/handlers/string_handler.rb",
     "lib/partigirb/handlers/xml_handler.rb",
     "lib/partigirb/transport.rb",
     "partigirb.gemspec",
     "test/atom_handler_test.rb",
     "test/client_test.rb",
     "test/fixtures/alvaro_friends.atom.xml",
     "test/fixtures/pulp_fiction.atom.xml",
     "test/json_handler_test.rb",
     "test/mocks/net_http_mock.rb",
     "test/mocks/response_mock.rb",
     "test/mocks/transport_mock.rb",
     "test/test_helper.rb",
     "test/transport_test.rb",
     "test/xml_handler_test.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/partigi/partigirb}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{TODO}
  s.test_files = [
    "test/atom_handler_test.rb",
     "test/client_test.rb",
     "test/json_handler_test.rb",
     "test/mocks/net_http_mock.rb",
     "test/mocks/response_mock.rb",
     "test/mocks/transport_mock.rb",
     "test/test_helper.rb",
     "test/transport_test.rb",
     "test/xml_handler_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
