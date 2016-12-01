describe Bothan do

  before(:each) do
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
    expect(bothan.heroku).to eq(@heroku_stub)
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
