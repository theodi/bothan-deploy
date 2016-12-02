describe Bothan do

  context 'creating' do

    before(:each) do
      @platform_api = double("PlatformAPI")
      @app_setup = double("PlatformAPI::AppSetup")
      @pusher_client = double(Pusher::Client)
      @pusher_channel = double(Pusher::Channel)
      allow(PlatformAPI).to receive(:connect_oauth).with('some-token').and_return(@platform_api)
      allow_any_instance_of(described_class).to receive(:pusher_client).and_return(@pusher_client)
      allow(@pusher_client).to receive(:[]).with('app_status').and_return(@pusher_channel)
      allow(@app_setup).to receive(:create).and_return({ 'id' => 'foo-bar' })
      allow(@platform_api).to receive(:app_setup).and_return(@app_setup).at_least(1).times
      allow_any_instance_of(Object).to receive(:sleep)
    end

    it 'builds and reports success' do
      expect(@app_setup).to receive(:info).with('foo-bar').and_return(pending_status, pending_status, complete_status)
      expect(@pusher_channel).to receive(:trigger).with('success', { url: 'http://example.org'})
      deployment = Bothan.create(token: 'some-token', params: {some: 'params', and: 'junk'})
    end

    it 'builds and reports an error' do
      expect(@app_setup).to receive(:info).with('foo-bar').and_return(pending_status, pending_status, pending_status, failed_status)
      expect(@pusher_channel).to receive(:trigger).with('failed', { message: 'This didn\'t work' })
      deployment = Bothan.create(token: 'some-token', params: {some: 'params', and: 'junk'})
    end

    it 'sets the correct env variables' do
      params = {
        'name' => 'my-awesome-app',
        'username' => 'username',
        'password' => 'password',
        'title' => 'This is a title',
        'description' => 'Here is a description',
        'license' => 'CC-BY-4.0',
        'publisherName' => 'Me',
        'publisherURL' => 'http://example.com'
      }

      # For some reason Odlifier won't work in test
      allow(Odlifier::License).to receive(:define).with('CC-BY-4.0') {
        Odlifier::License.new({
          title: "Creative Commons Attribution 4.0",
          url: "https://creativecommons.org/licenses/by/4.0/"
        })
      }

      expect(@app_setup).to receive(:create).with({
        app: {
          name: 'my-awesome-app'
        },
        source_blob: {
          url: 'https://github.com/theodi/bothan/tarball/master'
        },
        overrides: {
          env: {
            'METRICS_API_USERNAME'        => 'username',
            'METRICS_API_PASSWORD'        => 'password',
            'METRICS_API_TITLE'           => 'This is a title',
            'METRICS_API_DESCRIPTION'     => 'Here is a description',
            'METRICS_API_LICENSE_NAME'    => 'Creative Commons Attribution 4.0',
            'METRICS_API_LICENSE_URL'     => 'https://creativecommons.org/licenses/by/4.0/',
            'METRICS_API_PUBLISHER_NAME'  => 'Me',
            'METRICS_API_PUBLISHER_URL'   => 'http://example.com',
            'METRICS_API_CERTIFICATE_URL' => '#'
          }
        }
      }).and_return({ 'id' => 'foo-bar' })
      expect(@app_setup).to receive(:info).with('foo-bar').and_return(pending_status, pending_status, complete_status)
      expect(@pusher_channel).to receive(:trigger).with('success', { url: 'http://example.org'})
      deployment = Bothan.create(token: 'some-token', params: params)
    end

    it 'saves the app to the database' do
      expect(@app_setup).to receive(:info).with('foo-bar').and_return(pending_status, pending_status, complete_status)
      expect(@pusher_channel).to receive(:trigger).with('success', { url: 'http://example.org'})
      deployment = Bothan.create(token: 'some-token', params: {some: 'params', and: 'junk'})
      expect(Bothan.count).to eq(1)
      expect(Bothan.first.app_id).to eq('foo-bar')
      expect(Bothan.first.token).to eq('some-token')
    end

  end

  context 'updating' do

    before(:each) do
      allow_any_instance_of(Bothan).to receive(:create_app)
      allow_any_instance_of(Bothan).to receive(:check_status)

      @heroku_stub = double(PlatformAPI::Client)
      allow(PlatformAPI).to receive(:connect_oauth) {
        @heroku_stub
      }
    end

    it 'returns a heroku connection' do
      bothan = Bothan.create(app_id: '34234234', token: 'my-token')
      expect(PlatformAPI).to receive(:connect_oauth).with('my-token') {
        @heroku_stub
      }
      expect(bothan.send(:heroku)).to eq(@heroku_stub)
    end

    it 'creates a new build' do
      bothan = Bothan.create(app_id: '34234234', token: 'my-token')
      @build = double("PlatformAPI::Build")
      expect(@heroku_stub).to receive(:build) {
        @build
      }
      expect(@build).to receive(:create).with('34234234', {
        source_blob: {
          url: Bothan::SOURCE_BLOB
        }
      })
      bothan.build
    end

    it 'builds all bothans' do
      bothans = []
      5.times do |i|
        b = Bothan.create(app_id: i, token: "token-#{i}")
        expect(b).to receive(:build) { nil }
        bothans << b
      end
      expect(Bothan).to receive(:all) { bothans }
      Bothan.build_all
    end

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
