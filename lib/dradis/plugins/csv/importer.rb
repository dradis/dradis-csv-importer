module Dradis::Plugins::CSV
  class Importer < Dradis::Plugins::Upload::Importer
    def self.templates
      {}
    end

    def import(params={})
      logger.info { "Validating uploaded file..." }

      if File.extname(params[:file]).downcase != '.csv'
        logger.info { 'Invalid file' }
        return false
      end

      logger.info { 'Parsing CSV file...' }

      uid = @logger.uid

      # SEE: app/controllers/dradis/plugins/csv/upload_controller.rb
      Resque.redis.set(uid, File.basename(params[:file]))

      logger.info { 'Done' }
    end
  end
end

