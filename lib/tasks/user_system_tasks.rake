# Copyright (c) 2008 Todd Willey <todd@rubidine.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

begin
  require 'rcov/rcovtask'
rescue LoadError
  # do nothing
end

namespace :user_system do

  desc "Run migrations for the UserSystem Extension"
  task :migrate => :environment do
    require File.join(File.dirname(__FILE__), '..', '..', 'db', 'user_system_migrator')
    UserSystemMigrator.migrate(File.join(File.dirname(__FILE__), '..', '..', 'db', 'migrate'), ENV['VERSION'] ? ENV['VERSION'].to_i : nil)
  end

  desc 'Test the UserSystem Extension.'
  Rake::TestTask.new(:test) do |t|
    t.ruby_opts << "-r#{Rails.root}/test/test_helper"
    t.libs << File.join(File.dirname(__FILE__), '..', 'lib')
    t.pattern = File.join(File.dirname(__FILE__), '..', 'test/**/*_test.rb')
    t.verbose = true
  end

  desc 'Test the UserSystem Extension (only unit tests).'
  Rake::TestTask.new('test:units') do |t|
    t.ruby_opts << "-r#{Rails.root}/test/test_helper"
    t.libs << File.join(File.dirname(__FILE__), '..', 'lib')
    t.pattern = File.join(File.dirname(__FILE__), '..', 'test/unit/*_test.rb')
    t.verbose = true
  end

  desc 'Test the UserSystem Extension (only functional tests).'
  Rake::TestTask.new('test:functionals') do |t|
    t.ruby_opts << "-r#{Rails.root}/test/test_helper"
    t.libs << File.join(File.dirname(__FILE__), '..', 'lib')
    t.pattern = File.join(File.dirname(__FILE__), '..', 'test/functional/*_test.rb')
    t.verbose = true
  end

  if defined?(Rcov)
    desc 'Run code coverate analysis'
    Rcov::RcovTask.new do |t|
      require 'rbconfig'
      t.pattern = File.join(File.dirname(__FILE__), '..', 'test', '**', '*_test.rb')
      t.verbose = true

      myname = File.dirname(__FILE__).split('/')[-2]
      op = Dir[File.dirname(__FILE__) + '/../../*'].map{|x| File.basename(x)}
      op.reject!{|x| x == myname}
      unless op.empty?
        op = op.join(',')
        xo = "--exclude-only #{Config::CONFIG['prefix']},config,environment,vendor/rails,#{op},ext_lib,test"
      else
        xo = "--exclude-only #{Config::CONFIG['prefix']},config,environment,vendor/rails,ext_lib,test"
      end
      t.rcov_opts = [xo]
    end
  end

end
