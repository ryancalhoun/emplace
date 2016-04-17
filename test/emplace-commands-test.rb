require 'test/unit'

require 'emplace/app'

class TestEmplaceCommands < Test::Unit::TestCase

  def setup
    @commands = Emplace::Commands.new
  end

  def testToS
    assert_match /\s+create\s+/, @commands.to_s
  end

  def testFind
    assert_instance_of Emplace::App::Create, @commands.find('create')
  end

end

