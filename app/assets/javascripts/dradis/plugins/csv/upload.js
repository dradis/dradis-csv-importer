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
    function findNodeSelect() {
      return $('[data-behavior~=type-select]').toArray().find(function(typeSelect) {
        return typeSelect.value == 'Node Label';
      });
    }
    
    $('[data-behavior~=type-select]').on('change', function() {
      var $nodeSelect = $(findNodeSelect());

      $('[data-behavior~=type-select]').each(function(i, select) {
        if ($nodeSelect.length && !$nodeSelect.is($(select))) {
          $(select).find('option[value="Node Label"]').attr('disabled', 'disabled');
        } else {
          $(select).find('option[value="Node Label"]').removeAttr('disabled');
        }
      });
    });
  }
});
