module Dradis::Plugins::CSV
  class UploadController < ::AuthenticatedController
    include ProjectScoped

    before_action :load_attachment, only: [:new, :create]

    def new
      @default_columns = ['Unique Identifier', 'Column Header From File', 'Type', 'Field in Dradis']

      @headers = ::CSV.open(@attachment.fullpath, &:readline)

      @last_job = Log.new.uid
    end

    def create
      job_logger.write 'Enqueueing job to start in the background.'

      MappingImportJob.perform_later(
        file: @attachment.fullpath.to_s,
        id_index: mappings_params[:identifier],
        mappings: mappings_params[:mappings].to_h,
        project_id: current_project.id,
        uid: params[:item_id].to_i
      )

      head :ok
    end

    private

    def job_logger
      @job_logger ||= Log.new(uid: params[:item_id].to_i)
    end

    def load_attachment
      job_id = params[:job_id].to_i
      filename = Resque.redis.get(job_id)
      @attachment = Attachment.find(filename, conditions: { node_id: current_project.plugin_uploads_node.id })
    end

    def mappings_params
      params.permit(:identifier, mappings: [:field, :type])
    end
  end
end
