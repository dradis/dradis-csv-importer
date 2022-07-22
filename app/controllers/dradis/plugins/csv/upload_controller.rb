module Dradis::Plugins::CSV
  class UploadController < ::AuthenticatedController
    include ProjectScoped

    before_action :load_attachment, only: [:new, :create]
    before_action :load_csv_headers, only: [:new]

    def new
      @default_columns = ['Unique Identifier', 'Column Header From File', 'Type', 'Field in Dradis']

      @log_uid = Log.new.uid
    end

    def create
      job_logger.write 'Enqueueing job to start in the background.'

      MappingImportJob.perform_later(
        file: @attachment.fullpath.to_s,
        id_index: params[:identifier],
        mappings: mappings_params[:field_attributes].to_h,
        project_id: current_project.id,
        uid: params[:log_uid].to_i
      )

      Resque.redis.del(params[:job_id])
    end

    private

    def job_logger
      @job_logger ||= Log.new(uid: params[:log_uid].to_i)
    end

    def load_csv_headers
      begin
        @headers = ::CSV.open(@attachment.fullpath, &:readline)
      rescue CSV::MalformedCSVError => e
        return redirect_to main_app.project_upload_manager_path, alert: "The uploaded file is not a valid CSV file: #{e.message}"
      end
    end

    def load_attachment
      job_id = params[:job_id].to_i
      filename = Resque.redis.get(job_id)

      unless filename
        return redirect_to main_app.project_upload_manager_path
      end

      @attachment = Attachment.find(filename, conditions: { node_id: current_project.plugin_uploads_node.id })
    end

    def mappings_params
      params.require(:mappings).permit(field_attributes: [:field, :type])
    end
  end
end
