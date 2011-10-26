require "./build_hierarchy.rb"
require "./gemfile2freemind.rb"
GemlockToFreemind.new.generate_xml(File.join(".", "Gemfile.lock"), File.join(".", "Gemfile.mm"))