module Dradis::Plugins::CSV
  class UploadController < ::AuthenticatedController
    include ProjectScoped

    def new
      job_id = params[:job_id].to_i
      filename = Resque.redis.get(job_id)

      @attachment = Attachment.find(filename, conditions: { node_id: current_project.plugin_uploads_node.id })
    end
  end
end
