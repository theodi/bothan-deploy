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
      expect(Sidekiq::Extensions::DelayedClass.jobs.count).to eq(0)
      login!
      post '/deploy', { 'foo' => 'bar' }, { 'bouncer.token' => '12345' }
      expect(last_response.status).to eq(202)
      expect(Sidekiq::Extensions::DelayedClass.jobs.count).to eq(1)
    end

    it 'returns 412 if the signature is not provided' do
      post '/update', {payload: { thing: 'woooo' }.to_json }, {}
      expect(last_response.status).to eq(412)
    end

    it 'returns 401 if the signature is incorrect' do
      post '/update', {payload: { thing: 'woooo' }.to_json }, { 'HTTP_X_HUB_SIGNATURE' => 'sha1=9cb7f1850933d76def6f6e723dd76b541f744f59'}
      expect(last_response.status).to eq(401)
    end

    it 'works if the signature is correct' do
      post '/update', {payload: { thing: 'woooo' }.to_json }, { 'HTTP_X_HUB_SIGNATURE' => 'sha1=62957779cf2d2e83ad38d4d0c1d12d0fb76413d4'}
      expect(last_response.status).to eq(202)
    end

    it 'queues a deployment if the branch is master' do
      expect(Sidekiq::Extensions::DelayedClass.jobs.count).to eq(0)
      expect_any_instance_of(app).to receive(:verify_signature) { nil }
      post '/update', {payload: { ref: 'refs/heads/master' }.to_json }
      expect(last_response.status).to eq(202)
      expect(Sidekiq::Extensions::DelayedClass.jobs.count).to eq(1)
    end

    it 'serves the number of deploys as JSON data' do
      allow_any_instance_of(Bothan).to receive(:create_app)
      allow_any_instance_of(Bothan).to receive(:check_status)
      Bothan.create(token: 'some-token', params: {some: 'params', and: 'junk'})
      login!
      get '/statistics.json'
      expect(last_response.status).to eq(200)
      served_data = JSON.parse(last_response.body)
      expect(served_data["total_bothan_deploys"]).to eq 1
    end

  end
end
