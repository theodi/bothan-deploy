class Bothan < ActiveRecord::Base

  SOURCE_BLOB = 'https://github.com/theodi/bothan/tarball/master'

  def self.build_all
    Bothan.all.each { |b| b.build }
  end

  def build
    heroku.build.create(app_id, {
      source_blob: {
        url: SOURCE_BLOB
      }
    })
  end

  def heroku
    PlatformAPI.connect_oauth(token)
  end

end
