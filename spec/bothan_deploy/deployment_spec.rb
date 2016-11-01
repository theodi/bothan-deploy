module BothanDeploy
  describe Deployment do

    before(:each) do
      @platform_api = double("PlatformAPI")
      @app_setup = double("PlatformAPI::AppSetup")
      @mock_pusher = double(Pusher::Channel)
      allow(PlatformAPI).to receive(:connect_oauth).with('some-token').and_return(@platform_api)
      allow(Pusher).to receive(:[]).with('app_status').and_return(@mock_pusher)
      allow(@app_setup).to receive(:create).and_return({ 'id' => 'foo-bar' })
      allow(@platform_api).to receive(:app_setup).and_return(@app_setup).at_least(1).times
      allow_any_instance_of(Object).to receive(:sleep)
    end

    it 'initializes correctly' do
      deployment = described_class.new('some-token', {some: 'params', and: 'junk'})
      expect(deployment.instance_variable_get("@heroku")).to eq(@platform_api)
      expect(deployment.instance_variable_get("@params")).to eq({some: 'params', and: 'junk'})
    end

    it 'builds and reports success' do
      expect(@app_setup).to receive(:info).with('foo-bar').and_return(pending_status, pending_status, complete_status)
      expect(@mock_pusher).to receive(:trigger).with('success', { url: 'http://example.org'})
      deployment = described_class.new('some-token', {some: 'params', and: 'junk'})
      deployment.build
    end

    it 'builds and reports an error' do
      expect(@app_setup).to receive(:info).with('foo-bar').and_return(pending_status, pending_status, pending_status, failed_status)
      expect(@mock_pusher).to receive(:trigger).with('failed', { message: 'This didn\'t work' })
      deployment = described_class.new('some-token', {some: 'params', and: 'junk'})
      deployment.build
    end

    private

    def pending_status
      { 'status' => 'pending' }
    end

    def complete_status
      { 'status' => 'succeeded', 'resolved_success_url' => 'http://example.org' }
    end

    def failed_status
      { 'status' => 'failed', 'failure_message' => 'This didn\'t work' }
    end

  end
end
