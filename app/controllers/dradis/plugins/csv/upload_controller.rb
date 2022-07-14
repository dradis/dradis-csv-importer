module Dradis::Plugins::CSV
  class UploadController < ::AuthenticatedController
    include ProjectScoped

    skip_before_action :login_required, :ensure_tester, :setup_required, :verify_authenticity_token, :set_project, :set_nodes, :render_onboarding_tour, only: [:create]

    def new
      job_id = params[:job_id].to_i
      filename = Resque.redis.get(job_id)

      @attachment = Attachment.find(filename, conditions: { node_id: current_project.plugin_uploads_node.id })
    end

    def create
      MappingService.import(
        project: Project.find(params[:project_id]),
        file: Rails.root.join('HOLM-INFRA.csv'),
        issue_mappings: mappings_params[:issue_mappings],
        evidence_mappings: mappings_params[:evidence_mappings],
        csv_id_column: mappings_params[:csv_id_column_name],
        node_column: mappings_params[:node_column_name]
      )


    end

    private

    def mappings_params
      params.permit(
        :csv_id_column_name, :node_column_name,
        evidence_mappings: [:column_name, :field_name],
        issue_mappings: [:column_name, :field_name]
      )
    end
  end
end
