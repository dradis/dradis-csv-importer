require 'csv'

module Dradis::Plugins::CSV
  class MappingImportJob < ApplicationJob
    queue_as :dradis_project

    def perform(file:, identifier_col_index:, mappings:, project_id:, uid:)
      @logger = Log.new(uid: uid)
      @logger.write { "Job id is #{job_id}." }
      @logger.write { 'Worker process starting background task.' }

      @file = file
      @identifier_col_index = identifier_col_index
      @mappings = mappings
      @project = Project.find(project_id)
      node_col_mapping = @mappings.find { |index, field| field['type'] == 'node' }
      @node_col_index = node_col_mapping[0].to_i if node_col_mapping

      unless @identifier_col_index
        @logger.fatal('Unique Identifier doesn\'t exist, please choose a column as the Unique Identifier.')
        return
      end

      import_csv!

      @logger.write { 'Worker process completed.' }
    end

    private

    def content_service
      @content_service ||= Dradis::Plugins::ContentService::Base.new(
        project: @project,
        plugin: Dradis::Plugins::CSV
      )
    end

    def import_csv!
      @issue_mappings = @mappings.select { |index, mapping| mapping['type'] == 'issue' && mapping['field'].present? }
      @evidence_mappings = @mappings.select { |index, mapping| mapping['type'] == 'evidence' && mapping['field'].present? }

      CSV.foreach(@file, headers: true) do |row|
        process_row(row)
      end
    end

    def process_row(row)
      identifier = row[@identifier_col_index.to_i]

      @logger.info { "\t => Creating new issue (plugin_id: #{ identifier })" }

      issue_text = build_text(mappings: @issue_mappings, row: row)
      issue = content_service.create_issue(text: issue_text, id: identifier)

      node_label = row[@node_col_index]

      if node_label
        node = content_service.create_node(label: node_label, type: :host)
        @logger.info{ "\t => Creating new evidence (plugin_id: #{identifier})" }
        @logger.info { "\t\t => Issue: #{issue.title} (plugin_id: #{issue.to_issue.id})" }
        @logger.info { "\t\t => Node: #{node.label} (#{node.id})" }

        evidence_content = build_text(mappings: @evidence_mappings, row: row)
        content_service.create_evidence(issue: issue, node: node, content: evidence_content)
      end
    end

    def build_text(mappings:, row:)
      mappings.map do |index, mapping|
        field_name = mapping['field']
        field_value = row[index.to_i]
        "#[#{field_name}]#\n#{field_value}"
      end.join("\n\n")
    end
  end
end
