module Dradis::Plugins::CSV
  class UploadController < ::AuthenticatedController
    include ProjectScoped

    def new
      @default_columns = ['Unique Identifier', 'Column Header', 'Type']
      if current_project.report_template_properties
        @default_columns | ['Dradis Field']
      end

      parse_csv
    end

    def create
      redirect_to main_app.project_upload_manager_path(current_project)
    end

    private

    def parse_csv
      job_id = params[:job_id].to_i
      filename = Resque.redis.get(job_id)
      attachment = Attachment.find(filename, conditions: { node_id: current_project.plugin_uploads_node.id })

      @headers = ::CSV.open(attachment.fullpath, &:readline)
    end
  end
end
