require 'rails_helper'

RSpec.describe Dradis::Plugins::CSV::MappingImportJob do
  let(:file) { File.expand_path('../../../.../../../fixtures/files/simple.csv', __dir__) }
  let(:identifier) { '0' }

  let(:project) { create(:project) }

  let(:perform_job) do
    described_class.new.perform(
      file: file,
      id_index: identifier,
      mappings: mappings,
      project_id: project.id,
      uid: 1
    )
  end

  describe '#perform' do
    context 'when project has RTP' do
      before do
        project.update(report_template_properties: create(:report_template_properties))
      end

      let(:mappings) do
        {
          '1' => { 'type' => 'issue', 'field' => 'MyTitle' },
          '3' => { 'type' => 'node', 'field' => '' },
          '4' => { 'type' => 'evidence', 'field' => 'MyLocation' },
          '5' => { 'type' => 'evidence', 'field' => '' }
        }
      end

      it 'uses the field as Dradis Field' do
        perform_job

        issue = Issue.first
        expect(issue.fields).to eq({ 'MyTitle' => 'SQL Injection', 'plugin' => 'csv', 'plugin_id' => '1' })

        node = issue.affected.first
        expect(node.label).to eq('10.0.0.1')

        evidence = node.evidence.first
        expect(evidence.fields).to eq({ 'Label' => '10.0.0.1', 'Title' => '(No #[Title]# field)', 'MyLocation' => '10.0.0.1' })
      end
    end

    context 'when project does not have RTP' do
      let(:mappings) do
        {
          '1' => { 'type' => 'issue', 'field' => 'MyTitle' },
          '3' => { 'type' => 'node', 'field' => '' },
          '4' => { 'type' => 'evidence', 'field' => 'MyLocation' },
          '5' => { 'type' => 'evidence', 'field' => '' }
        }
      end

      it 'uses the column name as Dradis Field' do
        perform_job

        issue = Issue.first
        expect(issue.fields).to eq({ 'Title' => 'SQL Injection', 'plugin' => 'csv', 'plugin_id' => '1' })

        node = issue.affected.first
        expect(node.label).to eq('10.0.0.1')

        evidence = node.evidence.first
        expect(evidence.fields).to eq({ 'Label' => '10.0.0.1', 'Location' => '10.0.0.1', 'Port' => '443', 'Title' => 'SQL Injection' })
      end
    end

    context 'when mapping does not have a node type' do
      let(:mappings) do
        {
          '1' => { 'type' => 'issue' },
          '4' => { 'type' => 'evidence' }
        }
      end

      it 'does not create node and evidence' do
        perform_job

        issue = Issue.last
        expect(issue.affected.length).to eq(0)
        expect(issue.evidence.length).to eq(0)
      end
    end

    context 'when no identifer is passed in' do
      let(:identifier) { nil }

      let(:mappings) do
        {
          '1' => { 'type' => 'issue' },
          '4' => { 'type' => 'evidence' }
        }
      end

      it 'does not create any issue, node and evidence' do
        expect {
          perform_job
        }.to change(Issue, :count).by(0)

        expect(Node.count).to eq(0)
        expect(Evidence.count).to eq(0)
      end
    end
  end
end
