require 'csv'

module Dradis::Plugins::CSV
  class MappingService
    class << self
      def import(project:, file:, mappings:, identifier_col_index:)
        @identifier_col_index = identifier_col_index.to_i
        @project = project
        @file = file
        @mappings = mappings.to_h
        @node_col_index = @mappings.find { |index, field| field['type'] == 'Node Label' }[0].to_i

        CSV.foreach(@file, headers: true) do |row|
          process_row(row)
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
        identifier = row[@identifier_col_index.to_i]
        node_label = row[@node_col_index]

        issue_text = @mappings.select { |index, field| field['type'] == 'Issue Field' }.map do |index, field|
          field_name = field['field_name']
          field_value = row[index]
          "#[#{field_name}]#\n#{field_value}"
        end.join("\n\n")

        issue = content_service.create_issue(text: issue_text, id: identifier)
        node = content_service.create_node(label: node_label, type: :host)

        evidence_content = @mappings.select { |index, field| field['type'] == 'Issue Field' }.map do |index, field|
          field_name = field['field_name']
          field_value = row[index]
          "#[#{field_name}]#\n#{field_value}"
        end.join("\n\n")

        content_service.create_evidence(issue: issue, node: node, content: evidence_content)
      end
    end
  end
end
