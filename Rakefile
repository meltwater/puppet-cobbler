require 'rake'
require 'rspec/core/rake_task'
require 'puppetlabs_spec_helper/rake_tasks'

desc "Run all RSpec code examples"
RSpec::Core::RakeTask.new(:rspec) do |t|
  File.exist?('spec/spec.opts') ? opts = File.read("spec/spec.opts").chomp : opts = ""
  t.rspec_opts = opts
end

SPEC_SUITES = (Dir.entries('spec') - ['.', '..','fixtures']).select {|e| File.directory? "spec/#{e}" }
namespace :rspec do
  SPEC_SUITES.each do |suite|
    desc "Run #{suite} RSpec code examples"
    RSpec::Core::RakeTask.new(suite) do |t|
      t.pattern = "spec/#{suite}/**/*_spec.rb"
      File.exist?('spec/spec.opts') ? opts = File.read("spec/spec.opts").chomp : opts = ""
      t.rspec_opts = opts
    end
  end
end
task :default => :spec

begin
  if Gem::Specification::find_by_name('puppet-lint')
    require 'puppet-lint/tasks/puppet-lint'
    PuppetLint.configuration.ignore_paths = ["spec/**/*.pp", "vendor/**/*.pp"]
    task :default => [:spec, :lint]
  end
rescue Gem::LoadError
end

desc "Run Acceptance tests on CI with multiple nodes"
  task :ci  do
    sh('RS_SET=ci bundle exec rake beaker')
  end
