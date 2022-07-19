module Dradis::Plugins::CSV
  class UploadController < ::AuthenticatedController
    include ProjectScoped

    skip_before_action :login_required, :ensure_tester, :setup_required, :verify_authenticity_token, :set_project, :set_nodes, :render_onboarding_tour, only: [:create]

    def new
      parse_csv
    end

    def create
      MappingService.import(
        identifier_col_index: mappings_params[:identifier],
        mappings: mappings_params[:mappings],
        file: Rails.root.join('HOLM-INFRA.csv'),
        project: Project.find(params[:project_id])
      )
    end

    private

    def parse_csv
      job_id = params[:job_id].to_i
      filename = Resque.redis.get(job_id)
      attachment = Attachment.find(filename, conditions: { node_id: current_project.plugin_uploads_node.id })

      @headers = ::CSV.open(attachment.fullpath, &:readline)
    end

    def mappings_params
      params.permit(
        :identifier, mappings: [:type]
      )
    end
  end
end
