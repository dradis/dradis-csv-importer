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
    $('[data-behavior~=type-select]').on('click', function() {
      $(this).attr('data-original-value', $(this).val());
    });

    $('[data-behavior~=type-select]').on('change', function() {
      var $changedSelect = $(this);
      
      $('[data-behavior~=type-select]').each(function(i, select) {
        if ($(select).is($changedSelect)) { return; }

        if (($changedSelect).val() == 'Node Label') {
          $(select).find('option[value="Node Label"]').attr('disabled', 'disabled');
        } else if ($changedSelect.attr('data-original-value') == 'Node Label') {
          $(select).find('option[value="Node Label"]').removeAttr('disabled');
        }
      });
    });
  }
});
