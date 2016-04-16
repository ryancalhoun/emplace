require 'optparse'

module Emplace
  module App
    def self.run(args)
      options = OptionParser.new {|opts|
        opts.banner = "Usage: #{emplace} COMMAND [OPTIONS]"
        opts.on('-h', '--help', 'Show this help message') {
          exit_with opts
        }
        opts.on('-v', '--version', 'Print gem version') {
          exit_with "#{emplace} v#{Gem.loaded_specs[emplace].version}"
        }
        opts.separator ''
        opts.separator 'Commands:' + commands.to_s
        opts.separator ''
      }

      exit_with options if args.empty?

      begin
        options.order! args
      rescue OptionParser::ParseError => e
        STDERR.puts e
        exit_with options, 1
      end

      unless name = args.shift
        exit_with options
      end

      unless command = commands.find(name)
        STDERR.puts "error: unknown command #{name}"
        exit_with options, 1
      end

    end

    def self.commands
      @commands ||= Commands.new
    end

    def self.emplace
      Emplace.to_s.downcase
    end

    def self.exit_with(message, code = 0)
      puts message
      exit code
    end
  end
  class Commands
    def initialize
      @commands = [
        Create.new,
      ]
    end
    def find(name)
      @commands.select {|command|
        name_of(command) =~ /^#{name}/
      }.first
    end
    def name_of(command)
      command.class.name.split('::').last.downcase
    end
    def to_s
      "\n" + @commands.map {|command|
        sprintf "        %-28s %s", name_of(command), command.description
      }.join("\n")
    end
  end
  class Create
    def description
      "Create classes and test classes"
    end
    def run(args)
    end
  end
end
