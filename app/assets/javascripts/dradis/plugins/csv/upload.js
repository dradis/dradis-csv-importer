window.addEventListener('job-done', function(e){
  if ($('body.upload.index').length) {
    var jobId = e.detail.job_id,
        uploader = document.getElementById('uploader');

    if (uploader.value === 'Dradis::Plugins::CSV') {
      var path = window.location.pathname;
      var project_path = path.split('/').slice(0, -1).join('/');

      var redirectPath  = project_path + '/csv/upload/new?job_id=' + jobId;
      Turbolinks.visit(redirectPath);
    }
  }
});

document.addEventListener('turbolinks:load', function() {
  if ($('body.upload.new').length) {
    $('[data-behavior=type-select]').on('change', function(e) {
      var $nodeSelect = $('select option[value="node"]:selected').parent();

      // Disable Node Label option and update fields column labels
      $('[data-behavior=type-select]').each(function(i, select) {
        var $tr = $(select).closest('tr');

        $tr.find('[data-behavior=na-field-label]').addClass('d-none');
        $tr.find('[data-behavior=default-field-label]').removeClass('d-none');

        if ($nodeSelect.length && !$nodeSelect.is($(select))) {
          $(select).find('option[value="node"]').attr('disabled', 'disabled');
        } else {
          $(select).find('option[value="node"]').removeAttr('disabled');
        }
      });
      $nodeSelect.closest('tr').find('[data-behavior=na-field-label]').removeClass('d-none');
      $nodeSelect.closest('tr').find('[data-behavior=default-field-label]').addClass('d-none');

      // Update the field select with the one from the RTP
      var rtpFields = $('[data-behavior=dradis-datatable]').data('rtp-fields');
      if (rtpFields) {
        var fields = rtpFields[$(e.target).val()],
            $fieldSelect = $(e.target).closest('tr').find('[data-behavior=field-select]');

        $fieldSelect.empty();
        if (fields) {
          fields.forEach(function(value) {
            $fieldSelect.append($('<option></option>').attr('value', value).text(value));
          });
        }
      }
    });
  }
});
