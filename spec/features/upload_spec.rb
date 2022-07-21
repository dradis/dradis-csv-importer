require 'rails_helper'

# To run, execute from Dradis main app folder:
#   bin/rspec [dradis-plugins path]/spec/features/upload_spec.rb

describe 'upload feature', js: true do
  before do
    login_to_project_as_user
    visit project_upload_path(@project)
  end

  context 'uploading a CSV file' do
    let(:file_path) { File.expand_path('../fixtures/files/simple.csv', __dir__) }
    before do
      select 'Dradis::Plugins::CSV', from: 'uploader'

      within('.custom-file') do
        page.find('#file', visible: false).attach_file(file_path)
      end

      find('body.upload.new', wait: 30)
    end

    it 'redirects to the mapping page' do
      expect(current_path).to eq(csv.new_project_upload_path(@project))
    end

    it 'lists the fields in the table' do
      headers = CSV.open(file_path, &:readline)

      within('tbody') do
        headers.each do |header|
          expect(page).to have_selector('td', text: header)
        end
      end
    end

    context 'mapping CSV columns' do
      context 'when identifier not selected' do
        it 'shows a validation message on the page' do
          click_button 'Import CSV'

          message = page.find('#identifier_0').native.attribute('validationMessage')
          expect(message).to eq('Please select one of these options.')
        end
      end

      context 'when there are evidence type but no node type selected' do
        it 'shows a validation message on the page' do
          # Select identifer column
          find('#identifier_0').click

          within all('tbody tr')[4] do
            select 'Evidence Field'
          end

          click_button 'Import CSV'
          expect(page).to have_text('A Node Label Type must be selected to import evidence records.')
        end
      end

      context 'when project does not have RTP' do
        it 'imports all columns as fields' do
          # Select identifer column
          find('#identifier_0').click

          within all('tbody tr')[3] do
            select 'Node Label'
          end

          within all('tbody tr')[4] do
            select 'Evidence Field'
          end

          within all('tbody tr')[5] do
            select 'Evidence Field'
          end

          perform_enqueued_jobs do
            click_button 'Import CSV'

            find('#console .log', wait: 30, match: :first)

            expect(page).to have_text('Worker process completed.')

            issue = Issue.last
            expect(issue.fields).to eq({ 'Description' => 'Test CSV', 'Title' => 'SQL Injection', 'plugin' => 'csv', 'plugin_id' => '1' })

            node = issue.affected.first
            expect(node.label).to eq('10.0.0.1')

            evidence = node.evidence.first
            expect(evidence.fields).to eq({ 'Label' => '10.0.0.1', 'Title' => 'SQL Injection', 'Location' => '10.0.0.1', 'Port' => '443' })
          end
        end
      end

      context 'when project have RTP' do
        before do
          @evidence_fields = [
            { name: 'Location', type: :string, default: true },
            { name: 'Port', type: :string, default: true}
          ]
          @issue_fields = [
            { name: 'Title', type: :string, default: true },
            { name: 'Description', type: :string, default: true}
          ]

          rtp = create(:report_template_properties, evidence_fields: @evidence_fields, issue_fields: @issue_fields)

          @project.update(report_template_properties: rtp)

          page.refresh
        end

        it 'shows the available fields for the selected type' do
          select 'Issue Field', from: 'mappings[1][type]'

          within all('tbody tr')[1] do
            @issue_fields.each do |field|
              expect(page).to have_selector('option', text: field[:name])
            end
          end

          select 'Evidence Field', from: 'mappings[4][type]'

          within all('tbody tr')[4] do
            @evidence_fields.each do |field|
              expect(page).to have_selector('option', text: field[:name])
            end
          end
        end

        it 'auto-selects the type and field for the identifier' do
          # Select identifer column
          find('#identifier_0').click

          expect(page).to have_select('mappings[0][type]', selected: 'Issue Field', disabled: true)
          expect(page).to have_select('mappings[0][field]', selected: 'plugin_id', disabled: true)
        end

        it 'can select which columns to import' do
          # Select identifer column
          find('#identifier_0').click

          select 'Issue Field', from: 'mappings[1][type]'
          select 'Title', from: 'mappings[1][field]'

          select 'Issue Field', from: 'mappings[2][type]'
          select 'Description', from: 'mappings[2][field]'

          select 'Node Label', from: 'mappings[3][type]'

          select 'Evidence Field', from: 'mappings[4][type]'
          select 'Location', from: 'mappings[4][field]'

          select 'Evidence Field', from: 'mappings[5][type]'
          select 'Port', from: 'mappings[5][field]'

          perform_enqueued_jobs do
            click_button 'Import CSV'

            find('#console .log', wait: 30, match: :first)

            expect(page).to have_text('Worker process completed.')

            issue = Issue.last
            expect(issue.fields).to eq({ 'Description' => 'Test CSV', 'Title' => 'SQL Injection', 'plugin' => 'csv', 'plugin_id' => '1' })

            node = issue.affected.first
            expect(node.label).to eq('10.0.0.1')

            evidence = node.evidence.first
            expect(evidence.fields).to eq({ 'Label' => '10.0.0.1', 'Location' => '10.0.0.1', 'Title' => 'SQL Injection', 'Port' => '443' })
          end
        end
      end
    end
  end
end
