module BothanDeploy
  JSON_HEADERS = { 'HTTP_ACCEPT' => 'application/json' }

  describe App do
    it 'redirects to heroku auth' do
      get '/'
      expect(last_response).to be_redirect
    end
  end
end
