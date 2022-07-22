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

    it 'lists the fields in the table', focus: true do
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
            expect(issue.fields).to eq({ 'Description' => 'Test CSV', "Id" => '1', 'Title' => 'SQL Injection', 'plugin' => 'csv', 'plugin_id' => '1' })

            node = issue.affected.first
            expect(node.label).to eq('10.0.0.1')

            evidence = node.evidence.first
            expect(evidence.fields).to eq({ 'Label' => '10.0.0.1', 'Title' => 'SQL Injection', 'Location' => '10.0.0.1', 'Port' => '443' })
          end
        end
      end

      context 'when project have RTP' do
        before do
          @project.update(report_template_properties: create(:report_template_properties))
        end

        it 'can select which columns to import' do
          # Refresh to show text inputs
          page.refresh

          # Select identifer column
          find('#identifier_0').click

          within all('tbody tr')[1] do
            select 'Issue Field'
            find('input[type="text"]').fill_in(with: 'MyTitle')
          end

          within all('tbody tr')[3] do
            select 'Node Label'
          end

          within all('tbody tr')[4] do
            select 'Evidence Field'
            find('input[type="text"]').fill_in(with: 'MyLocation')
          end

          perform_enqueued_jobs do
            click_button 'Import CSV'

            find('#console .log', wait: 30, match: :first)

            expect(page).to have_text('Worker process completed.')

            issue = Issue.last
            expect(issue.fields).to eq({ 'MyTitle' => 'SQL Injection', 'plugin' => 'csv', 'plugin_id' => '1' })

            node = issue.affected.first
            expect(node.label).to eq('10.0.0.1')

            evidence = node.evidence.first
            expect(evidence.fields).to eq({ 'Label' => '10.0.0.1', 'MyLocation' => '10.0.0.1', 'Title' => '(No #[Title]# field)' })
          end
        end
      end
    end
  end

  context 'uploading a malformed CSV file' do
    let(:file_path) { File.expand_path('../fixtures/files/simple_malformed.csv', __dir__) }
    before do
      select 'Dradis::Plugins::CSV', from: 'uploader'

      within('.custom-file') do
        page.find('#file', visible: false).attach_file(file_path)
      end
    end

    it 'redirects to upload manager' do
      expect(page).to have_text('The uploaded file is not a valid CSV file')
      expect(current_path).to eq(main_app.project_upload_manager_path(@project))
    end
  end
end
