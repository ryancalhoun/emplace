require 'fileutils'

module Emplace

  class Project
    def initialize(name, impl = Emplace.load_env)
      @name = name
      @impl = impl
    end
    def clean!
      @impl.clean
    end
    def cmake!
      @impl.cmake @name
    end
    def build!
      @impl.build
    end
    def test!
      @impl.test
    end
    def package!
      @impl.package @name
    end
  end

  class CMakeBuild
    def build_dir
      'build'  
    end
    def dist_dir
      'dist'
    end
    def install_dir(name)
      "#{dist_dir}/#{name}"
    end
    def cmake(name)
      sh "cmake . -B#{build_dir} -DCMAKE_INSTALL_PREFIX=#{install_dir(name)} -G \"#{cmake_generator}\""
    end
    def build
      sh "cmake --build #{build_dir} --target install"
    end
    def test
      sh "ctest --verbose", build_dir
    end
    def clean
      FileUtils.rm_rf build_dir
      FileUtils.rm_rf dist_dir
    end
    def sh(cmd, dir = '.')
      Dir.chdir(dir) {
        raise $? unless system cmd
      }
    end
  end

  class Unix < CMakeBuild
    def cmake_generator
      'Unix Makefiles'
    end
    def arch
      1.size == 4 ? 'x86' : 'x86_64'
    end
    def package_name(name)
      "#{name}-#{system_name}.tgz"
    end
    def package(name)
      sh "tar czf #{package_name(name)} #{name}", dist_dir
    end
  end

  class Linux < Unix
    def system_name
      "linux-#{arch}"
    end
  end

  class Darwin < Unix
    def system_name
      "osx-#{arch}"
    end
  end

  class Windows < CMakeBuild
    def system_name
      "win-#{arch}"
    end
    def package_name(name)
      "#{name}-#{system_name}.zip"
    end
  end

  module Travis
    def system_name
      if cc = ENV['CC']
        "#{super}-#{cc}"
      else
        super
      end
    end
  end

  module AppVeyor
    def cmake_generator
      case arch
      when 'x86'
        'Visual Studio 14'
      when 'x64'
        'Visual Studio 14 Win64'
      end
    end
    def arch
      case ENV['PLATFORM']
      when'x64'
        'x64'
      else
        'x86'
      end
    end
    def system_name
      if cfg = ENV['CONFIGURATION']
        "#{super}-msvc-#{cfg.downcase}"
      else
        "#{super}-msvc"
      end
    end
    def build
      if cfg = ENV['CONFIGURATION']
        sh "cmake --build #{build_dir} --target install --config #{cfg}"
      else
        super
      end
    end
    def package(name)
      sh "7z a #{package_name(name)} #{name}", dist_dir
    end
  end

  def self.load_env
    case RUBY_PLATFORM
    when /mswin|mingw/
      Windows
    when /darwin/
      Darwin
    when /linux/
      Linux
    else
      Unix
    end.tap {|platform|
      if ENV['TRAVIS']
        platform.send(:include, Travis)
      elsif ENV['APPVEYOR']
        platform.send(:include, AppVeyor) 
      end
    }.new
  end

end

