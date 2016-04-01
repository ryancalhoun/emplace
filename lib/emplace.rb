require 'fileutils'

module Emplace

  class Project
    def initialize(name, opts = {}, impl = Emplace.load_env)
      @name = name
      @opts = opts
      @impl = impl
    end
    def module_dir
      File.join(File.dirname(File.dirname(__FILE__)), 'modules')
    end
    def build_dir
      'build'
    end
    def dist_dir
      'dist'
    end
    def vendor_dir
      'vendor'
    end
    def clean!
      FileUtils.rm_rf build_dir
      FileUtils.rm_rf dist_dir
      FileUtils.rm_rf vendor_dir
    end
    def cmake!
      @impl.cmake @name, module_dir, build_dir, dist_dir
    end
    def build!
      @impl.build build_dir
    end
    def test!
      @impl.test build_dir
    end
    def package!
      @impl.package @name, dist_dir
    end
    def extract!
      @impl.extract @name, vendor_dir
    end
    def fetch!
      @impl.fetch(@name, @opts, vendor_dir)
    end
    private
    def fetch_url
      @impl.fetch_url(@opts[:url], @opts[:version])
    end
  end

  class CMakeBuild
    def cmake(name, module_dir, build_dir, dist_dir)
      sh "cmake . -B#{build_dir} -DCMAKE_MODULE_PATH=#{module_dir} -DCMAKE_INSTALL_PREFIX=#{dist_dir}/#{name} -G \"#{cmake_generator}\""
    end
    def build(dir)
      sh "cmake --build #{dir} --target install"
    end
    def test(dir)
      sh "ctest --verbose", dir
    end
    def sh(cmd, dir = '.')
      Dir.chdir(dir) {
        raise $? unless system cmd
      }
    end
    def fetch(name, opts, vendor_dir)
      package = package_name(name)
      url = File.join(opts[:url], opts[:version])

      IO.popen(['curl', '-fsSL', File.join(url, package)]) {|source|
        write_file(package, vendor_dir) {|dest|
          IO.copy_stream(source, dest)
        }
      }
    end
    def write_file(name, dir, &block)
      FileUtils.mkdir_p(dir)
      File.open(File.join(dir, name), 'wb', &block)
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
    def package(name, dir)
      sh "tar czf #{package_name(name)} #{name}", dir
    end
    def extract(name, dir)
      sh "tar xzf #{package_name(name)}", dir
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
    def cmake_generator
      case arch
      when 'x86'
        'Visual Studio 14'
      when 'x64'
        'Visual Studio 14 Win64'
      end
    end
    def arch
      case platform
      when'x64'
        'x64'
      else
        'x86'
      end
    end
    def system_name
      "#{super}-msvc"
    end
    def build(dir)
      sh "cmake --build #{dir} --target install --config #{configuration}"
    end
    def package(name, dir)
      sh "7z a #{package_name(name)} #{name}", dir
    end
    def extract(name, dir)
      sh "7z x #{package_name(name)}", dir
    end
    def system_name
      "win-#{arch}"
    end
    def package_name(name)
      "#{name}-#{system_name}.zip"
    end
    def platform
      ENV['PLATFORM'] || 'x64'
    end
    def configuration
      ENV['CONFIGURATION'] || 'Debug'
    end
  end

  private

  def self.local(base)
    Class.new(base) {
      def fetch(name, opts, vendor_dir)
        FileUtils.mkdir_p(vendor_dir)
        FileUtils.cp "../#{name}/dist/#{package_name(name)}", vendor_dir        
      end
    }
  end

  def self.travis(base)
    Class.new(base) {
      def system_name
        if cc = ENV['CC']
          "#{super}-#{cc}"
        else
          super
        end
      end
    }
  end

  def self.appveyor(base)
    Class.new(base) {
      def system_name
        "#{super}-msvc-#{configuration.downcase}"
      end
    }
  end

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
      travis platform
    elsif ENV['APPVEYOR']
      appveyor platform
    else
      local platform
    end.new
  end

end

