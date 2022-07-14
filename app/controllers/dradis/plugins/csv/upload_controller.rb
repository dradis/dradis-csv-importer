module Dradis::Plugins::CSV
  class UploadController < ::AuthenticatedController
    include ProjectScoped

    def new
      issue_mappings = {
       'Vulnerability Name' => 'Title',
       'Severity' => 'Severity',
       'Vulnerability Category' => 'Category',
       'CVSS Base' => 'CVSSv3.BaseScore',
       'Vulnerability Impact' => 'Impact',
       'Vulnerability Vendor Reference' => 'Reference',
       'Solution Information' => 'Solution',
      }

      evidence_mappings = {
        'OS' => 'OS',
        'Port' => 'Port'
      }

      node_column = 'Host address'
      csv_id_column = 'Holm Identifier'

      attachment = Rails.root.join('HOLM-INFRA.csv')
      byebug
      MappingService.import(
        project: current_project,
        file: attachment,
        issue_mappings: issue_mappings,
        evidence_mappings: evidence_mappings,
        csv_id_column: csv_id_column,
        node_column: node_column
      )

      job_id = params[:job_id].to_i
      filename = Resque.redis.get(job_id)

      @attachment = Attachment.find(filename, conditions: { node_id: current_project.plugin_uploads_node.id })
    end
  end
end
