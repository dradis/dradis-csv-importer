module Dradis::Plugins::CSV
  class Importer < Dradis::Plugins::Upload::Importer
    def self.templates
      {}
    end

    def import(params={})
      logger.info { 'Parsing CSV file...' }
      logger.info { 'Done' }
    end
  end
end

