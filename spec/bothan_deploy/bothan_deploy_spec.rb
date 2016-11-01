module BothanDeploy
  JSON_HEADERS = { 'HTTP_ACCEPT' => 'application/json' }

  describe App do
    it 'redirects to heroku auth' do
      get '/'
      expect(last_response).to be_redirect
    end

    it 'shows the form' do
      login!
      get '/'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to match /Deploy your own Bothan/
    end

    it 'queues a deploy job' do
      login!
      post '/deploy', { 'foo' => 'bar' }, { 'bouncer.token' => '12345' }
      expect(last_response.status).to eq(202)
    end
  end
end
