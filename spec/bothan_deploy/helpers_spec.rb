class TestHelper
  include BothanDeploy::Helpers
end

module BothanDeploy
  describe Helpers do
    let(:helpers) { TestHelper.new }

    it 'says hello' do
      expect(helpers.hello).to eq 'Hello'
    end
  end
end
