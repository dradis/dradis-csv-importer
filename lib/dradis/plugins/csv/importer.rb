module Dradis::Plugins::CSV
  class Importer < Dradis::Plugins::Upload::Importer
    def self.templates
      {}
    end

    def import(params={})
      logger.info { 'Parsing CSV file...' }

      uid = @logger.uid

      # SEE: app/controllers/dradis/plugins/csv/upload_controller.rb
      Resque.redis.set(uid, File.basename(params[:file]))

      logger.info { 'Done' }
    end
  end
end

