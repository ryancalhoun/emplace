require 'test/unit'

require 'emplace'

ENV['CC'] = 'cc'
ENV['CONFIGURATION'] = 'CFG'

class TestEmplace < Test::Unit::TestCase

  def testSystemName
    assert_equal 'linux-x86_64-cc', Travis.new.system_name
    assert_equal 'win-x64-msvc-cfg', AppVeyor.new.system_name
  end

  def testPackageName
    assert_equal 'foo-linux-x86_64-cc.tgz', Travis.new.package_name('foo')
    assert_equal 'foo-win-x64-msvc-cfg.zip', AppVeyor.new.package_name('foo')
  end

  def testCmakeGenerator
    assert_equal 'Unix Makefiles', Travis.new.cmake_generator
    assert_equal 'Visual Studio 14 Win64', AppVeyor.new.cmake_generator
  end

  class Travis < Emplace::Linux
    include Emplace::Travis
    def arch
      'x86_64'
    end
  end

  class AppVeyor < Emplace::Windows
    include Emplace::AppVeyor
    def arch
      'x64'
    end
  end

end
