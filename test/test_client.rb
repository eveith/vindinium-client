require 'minitest/autorun'
require 'webmock/minitest'

class ClientTest < MiniTest::Unit::TestCase
  def setup
    @faux_game_state = JSON.parse File.read(
      File.expand_path(__FILE__ + '/../webmock/game_state.json'))
    @faux_game_state['game']['turn'] = 0
    @faux_game_state['game']['finished'] = false

    @finished_game_state = JSON.parse File.read(
      File.expand_path(__FILE__ + '/../webmock/game_state.json'))

    stub_request(:post, 'http://vindinium.org/api/training')
      .with(body: %q/key=my_key/)
      .to_return( status: 200, body: @faux_game_state.to_json)
    stub_request(:post, 'http://vindinium.org/api/training')
      .with(body: { "key" => "my_key", "turns" => '300' })
      .to_return( status: 200, body: @faux_game_state.to_json)
  end

  def test_that_it_loops
    stub_move = stub_request(
        :post, "http://localhost:9000/api/s2xh3aig/lte0/play")
      .with(body: { "key" => "my_key", "dir" => "North" })
      .to_return(status: 200, body: @finished_game_state.to_json)

    turns = 0
    client = Vindinium::Client.new('my_key').start_training do |game_state|
      assert_equal turns, game_state.turn
      assert turns == 0 && game_state.running? || turns > 0 && !game_state.running?
      game_state.move! :north
      assert_equal @finished_game_state['game']['turn'], game_state.turn

      turns += 1
    end
  end

  def test_that_it_does_an_api_call
    client = Vindinium::Client.new 'my_key'
    state = client.api_call Vindinium::Client::BASE_URI_TRAINING

    assert state.has_key? 'game'
  end

  def test_that_it_raises_on_error
    stub_request(:post, 'http://vindinium.org/api/training')
      .with(body: { "key" => "wrong_key" })
      .to_return(status: 400, body: "You supplied the wrong key")
    client = Vindinium::Client.new 'wrong_key'
    assert_raises RuntimeError do
      client.api_call Vindinium::Client::BASE_URI_TRAINING
    end
  end

  def test_that_it_submits_training_parameters
    training_request = stub_request(:post, 'http://vindinium.org/api/training')
      .with(body: { "key"=>"tkey", "map"=>"m1", "turns"=>"2" })
      .to_return( status: 200, body: @faux_game_state.to_json)

    client = Vindinium::Client.new 'tkey'
    client.start_training map: 'm1', turns: 2

    assert_requested training_request
  end
end
