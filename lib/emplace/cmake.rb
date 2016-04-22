require 'fileutils'

module Emplace
  class CMake
    CMAKE_LISTS = 'CMakeLists.txt'

    attr_reader :path, :file

    def initialize(path = Dir.pwd, file = CMAKE_LISTS)
      @path = File.absolute_path path
      @file = file
      @lines = Lines.new
    end

    def has_cmake_lists?
      File.exists?(cmake_lists)
    end

    def cmake_lists
      @cmake_lists ||= File.join(path, file)
    end

    def cmake_contents
      unless @lines.done?
        read_cmake_file{|f| parse_cmake_file! f}
      end
      @lines
    end

    def project_name
      @project_name ||= cmake_contents.get_name('project')
    end

    def library_name
      @libary_name ||= cmake_contents.get_name('add_library')
    end

    def executable_name
      @executable_name ||= cmake_contents.get_name('add_executable')
    end

    def is_root?
      !! project_name && ! library_name && ! executable_name
    end

    def find_root
      cmake = self
      until cmake.is_root?
        parent = File.dirname(cmake.path)
        raise 'cannot find root of cmake project' if cmake.path == parent
        cmake = CMake.new parent
      end
      cmake
    end

    def statements
      cmake_contents.select {|line| line.is_a? Statement}
    end

    def to_s
      cmake_contents.to_s
    end

    def save!
      FileUtils.mkdir_p path
      File.open(cmake_lists, 'w') {|f|
        f.write to_s
      }
    end

    def set_project!(name)
      acquire!('project').arguments = [name]
    end

    def apply_template!(template)
      cmake_contents.apply_template! template
    end

    GLOBAL_STATEMENTS = %w(
      include_directories
      link_libraries
      link_directories
      enable_testing
    )

    TARGET_STATEMENTS = %w(
      add_executable
      add_library
      add_test
      target_link_libraries
    )

    def merge!(project)
      project.statements.each {|other|
        case other.name
        when 'project'
          set_project! other.arguments.first
        when *GLOBAL_STATEMENTS
          if mine = find(other.name) 
            other.arguments.each {|arg| mine.arguments << arg}
          else
            @lines << other
          end 
        when *TARGET_STATEMENTS
          if mine = find(other.name, other.arguments.first) 
            target,*args = other.arguments
            args.each {|arg| mine.arguments << arg}
          else
            @lines << other
          end 
        end
      }
    end

    def library(name)
      Target.new('add_library', name, self)
    end

    def parse_cmake_file!(io)
      io.each_line {|line| @lines.add_line line}
    end

    def find_all(name, *args)
      cmake_contents.find_all(name, *args)
    end

    def find(name, *args)
      cmake_contents.find(name, *args)
    end

    def acquire!(name, *args)
      cmake_contents.acquire!(name, *args)
    end

    class Lines
      include Enumerable
      def initialize
        @lines = []
      end
      def done?
        ! @lines.empty? && @lines.last.done?
      end
      def apply_template!(template)
        @lines.each {|line|
          line.apply_template! template
        }
      end
      def add_line(line)
        if @lines.last && ! @lines.last.done?
          @lines.last.add_line line
        elsif /^\s*(#.*)?$/.match(line)
          @lines << Whitespace.new(line)
        else
          @lines << Statement.create_from(line)
        end
      end
      def pop
        @lines.pop
      end
      def last
        @lines.last
      end
      def statements
        @lines.select {|line| line.is_a? Statement }
      end
      def to_s
        @lines.map {|line|
          line.to_s.chomp
        }.join("\n") + "\n"
      end
      def each(&block)
        @lines.each(&block)
      end
      def get_name(name)
        if s = find(name)
          s.arguments.first
        end
      end

      def find_all(name, *args)
        statements.find_all {|s|
          s.name.downcase == name.downcase && s.arguments.first(args.length) == args
        }
      end

      def find(name, *args)
        find_all(name, *args).first
      end

      def acquire!(name, *args)
        s = find(name, *args)
        unless s
          s = Command.new(name)
          args.each {|arg|
            s.arguments << arg
          }
          @lines << s
        end
        s
      end
    end

    class Line
      attr_reader :text
      def initialize(text)
        @text = text
      end
      def apply_template!(template)
        template.each {|key,val|
          text.gsub! "%#{key}%", val
        }
      end
      def done?
        true
      end
    end

    class Whitespace < Line
      def to_s
        text
      end
    end

    class Statement < Line
      def self.create_from(text)
        command = Command.new text
        case command.name
        when 'if'
          IfElse.new command
        when 'foreach'
          Foreach.new command
        else
          command
        end
      end
    end

    class Command < Statement
      attr_reader :name, :arguments
      def initialize(text)
        super
        @arguments = ArgumentList.new(self)
        if /^\w+$/.match(text.chomp)
          @name = text.chomp
        elsif m = /^\s*(\w+)\s*\(([^)]*)\)?/.match(text)
          @name = m[1]
          split_args m[2]
        end
      end
      def apply_template!(template)
        super
        arguments.apply_template!(template)
      end
      def arguments=(arguments)
        @arguments.clear.concat arguments
      end
      def done?
        !! /\)\s*$/m.match(text)
      end
      def add_line(line)
        @text += line
        if m = /([^)]*)\)?/.match(line)
          split_args m[1]
        end
      end
      def split_args(text)
        @arguments.concat text.split(/\s(?=(?:[^"]|"[^"]*")*$)|[\r\n]/).select {|a| ! a.empty?}
      end
      def to_s
        if /ies$/.match(name)
          "#{name}(#{arguments.map {|arg| "\n\t#{arg}"}.join}\n)"
        else
          "#{name}(#{arguments.to_s})"
        end
      end
    end

    class Branch < Statement
      def initialize(command)
        @commands = [[command, Lines.new]]
      end
      def name
        @commands.first[0].name
      end
      def arguments
        @commands.first[0].arguments
      end
      def apply_template!(template)
        @commands.each {|branch,command|
          branch.apply_template! template
          command.apply_template! template
        }
      end
      def add_line(line)
        if ! @commands.last[0].done?
          @commands.last[0].add_line line
        else
          @commands.last[1].add_line line
          if is_branch? @commands.last[1].last
            branch = @commands.last[1].pop
            @commands.push [branch, Lines.new]
          end
        end
      end
    end

    class IfElse < Branch
      def is_branch?(command)
        command.name == 'endif' || command.name == 'elseif' || command.name == 'else'
      end
      def done?
        @commands.last[0].name == 'endif' && @commands.last[0].done?
      end
      def get(name = nil, arg = nil)
        if name 
          if branch = @commands.find {|s|
            s[0].name.downcase == name.downcase && (! arg || s[0].arguments.first == arg)
          }
            branch[1]
          end
        else
          @commands.first[1]
        end
      end
    end
    class Foreach < Branch
      def is_branch?(command)
        command.name == 'endforeach'
      end
      def done?
        @commands.last[0].name == 'endforeach' && @commands.last[0].done?
      end
      def get
        @commands.first[1]
      end
    end

    class ArgumentList < Array
      def initialize(statement)
        @statement = statement
      end
      def apply_template!(template)
        each {|arg|
          template.each {|key,val|
            arg.gsub! "%#{key}%", val
          }
        }
      end
      def to_s
        join(' ')
      end
    end


    private
    def read_cmake_file(&block)
      begin
        File.open(cmake_lists, 'r', &block) 
      rescue Errno::ENOENT
      end
    end

  end
end
