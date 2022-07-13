module Dradis::Plugins::CSV
  class Engine < ::Rails::Engine
    isolate_namespace Dradis::Plugins::CSV

    include ::Dradis::Plugins::Base
    description 'Processes CSV output'
    provides :upload
  end
end
