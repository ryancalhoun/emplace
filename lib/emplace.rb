module Emplace

  class CmakeBuild
    def cmake
      sh "cmake -G \"#{cmake_generator}\" ."
    end
    def build
      sh "cmake --build . --target install"
    end
    def sh(cmd)
      raise $? unless system cmd
    end
  end

  class Unix < CmakeBuild
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
      sh "tar czf #{package_name(name)} #{name}"
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

  class Windows < CmakeBuild
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
    def package(name)
      sh "7z a #{package_name(name)} #{name}"
    end
  end

  private
  def self.load_env
    platform = case RUBY_PLATFORM
    when /mswin|mingw/
      Windows
    when /darwin/
      Darwin
    when /linux/
      Linux
    else
      Unix
    end

    if ENV['TRAVIS']
      platform.send(:include, Travis)
    elsif ENV['APPVEYOR']
      platform.send(:include, AppVeyor) 
    end

    platform.new.tap {|impl|
      (impl.methods - Object.methods).each {|m|
        define_singleton_method(m) {|*args,&block| impl.method(m).call(*args, &block) }
      }
    }
  end

  IMPL = load_env
end

