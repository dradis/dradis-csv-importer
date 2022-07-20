module Dradis::Plugins::CSV
  class UploadController < ::AuthenticatedController
    include ProjectScoped

    before_action :load_attachment, only: [:new]
    before_action :load_rtp_fields, only: [:new]

    def new
      @default_columns = ['Unique Identifier', 'Column Header From File', 'Type', 'Field in Dradis']
      @headers = ::CSV.open(@attachment.fullpath, &:readline)
    end

    def create
      redirect_to main_app.project_upload_manager_path(current_project)
    end

    private

    def load_rtp_fields
      rtp = current_project.report_template_properties
      @rtp_fields =
        unless rtp.nil?
          {
            evidence: rtp.evidence_fields.map(&:name),
            issue: rtp.issue_fields.map(&:name)
          }
        end
    end

    def load_attachment
      job_id = params[:job_id].to_i
      filename = Resque.redis.get(job_id)
      @attachment = Attachment.find(filename, conditions: { node_id: current_project.plugin_uploads_node.id })
    end
  end
end
