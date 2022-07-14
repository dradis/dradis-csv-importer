window.addEventListener('job-done', function(e){
  var uploader = document.getElementById('uploader');

  if (uploader.value === 'Dradis::Plugins::CSV') {
    var path = window.location.pathname;
    var project_path = path.split('/').slice(0, -1).join('/');

    window.location.href = project_path + '/csv/upload/new';
  }
});
