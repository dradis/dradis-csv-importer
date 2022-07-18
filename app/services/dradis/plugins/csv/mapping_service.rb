require 'csv'

module Dradis::Plugins::CSV
  class MappingService
    class << self
      def import(params = {})
        @csv_id_column = params[:csv_id_column]
        @evidence_mappings = params[:evidence_mappings]
        @file = params[:file]
        @issue_mappings = params[:issue_mappings]
        @node_column = params[:node_column]
        @project = params[:project]

        begin
          CSV.foreach(@file, headers: true) do |row|
            process_row(row)
          end
          # logger.info{ "CSV processed." }
        rescue ::CSV::MalformedCSVError => e
          error = "The CSV seems to be malformed: #{e.message}."
          # logger.fatal { error }
          content_service.create_note(text: error)
          false
        end
      end

      private

      def content_service
        @content_service ||= Dradis::Plugins::ContentService::Base.new(
          project: @project,
          plugin: Dradis::Plugins::CSV
        )
      end

      def process_row(row)
        data = row.to_h
        csv_id = data[@csv_id_column]
        node = data[@node_column]

        issue_text = @issue_mappings.to_h.map do |_key, mapping|
          "#[#{mapping[:field_name]}]#\n#{data[mapping[:column_name]]}"
        end.join("\n\n")

        issue = content_service.create_issue(text: issue_text, id: csv_id)
        node = content_service.create_node(label: node, type: :host)

        evidence_content = @evidence_mappings.to_h.map do |_key, mapping|
          "#[#{mapping[:field_name]}]#\n#{data[mapping[:column_name]]}"
        end.join("\n\n")

        content_service.create_evidence(issue: issue, node: node, content: evidence_content)
      end
    end
  end
end
