module BothanDeploy
  JSON_HEADERS = { 'HTTP_ACCEPT' => 'application/json' }

  describe App do
    it 'redirects to heroku auth' do
      get '/'
      expect(last_response).to be_redirect
    end
    it 'queues a deploy job' do
      login!
      post '/deploy', { 'foo' => 'bar' }, { 'bouncer.token' => '12345' }
      expect(last_response.status).to eq(202)
    end
  end
end
