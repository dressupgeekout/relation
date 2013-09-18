#
# = Rakefile
#
# == Christian Koch [cfkoch@sdf.lonestar.org]
#

RDOC = "rdoc193"
TESTER = "bacon"

task :default => :docs

desc "Make documentation."
task :docs do
  begin
    sh %Q(#{RDOC} -a)
  rescue
  end
end

desc "Run tests."
task :tests do
  begin
    sh %Q(#{TESTER} test/relation_test.rb)
  rescue
  end
end
