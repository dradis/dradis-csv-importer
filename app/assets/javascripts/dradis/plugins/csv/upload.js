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

      // Disable Node Label option
      $('[data-behavior=type-select]').each(function(i, select) {
        var $tr = $(select).closest('tr');
        if ($nodeSelect.length && !$nodeSelect.is($(select))) {
          $(select).find('option[value="node"]').attr('disabled', 'disabled');
        } else {
          $(select).find('option[value="node"]').removeAttr('disabled');
        }
      });

      // Update fields column labels
      var hasNoFields = $(e.target).val() == 'skip' || $(e.target).val() == 'node';
      if (hasNoFields) {
        $(e.target).closest('tr').find('[data-behavior=field-label]').text('N/A');
      }
      else {
        var header = $(e.target).closest('tr').find('td:nth-child(2)').text();
        $(e.target).closest('tr').find('[data-behavior=field-label]').text(header);
      }


      setDradisFieldSelect($(e.target));
    });

    $('[data-behavior=identifier]').on('mousedown', function(e){
      var $fieldSelect = $(e.target).closest('tr').find('[data-behavior=field-select]'),
          $typeSelect = $(e.target).closest('tr').find('[data-behavior=type-select]');

      $fieldSelect.attr('disabled', 'disabled');
      // With RTP
      $fieldSelect.html($('<option selected></option>').attr('value', 'plugin_id').text('plugin_id'));
      // With no RTP
      $(e.target).closest('tr').find('[data-behavior=field-label]').text('plugin_id');

      $typeSelect.attr('disabled', 'disabled');
      $typeSelect.val('issue').change();

      var $prevIdentifier = $('[data-behavior=identifier]:checked'),
          $prevFieldSelect = $prevIdentifier.closest('tr').find('[data-behavior=field-select]'),
          $prevTypeSelect = $prevIdentifier.closest('tr').find('[data-behavior=type-select]');

      $prevFieldSelect.removeAttr('disabled');

      $prevTypeSelect.removeAttr('disabled')
      // With RTP
      setDradisFieldSelect($prevTypeSelect);
      // With no RTP
      var header = $prevIdentifier.closest('tr').find('td:nth-child(2)').text();
      $prevIdentifier.closest('tr').find('[data-behavior=field-label]').text(header);
    });

    $('[data-behavior~=mapping-form]').submit(function() {
      var valid = validateNodeSelected();

      if (!valid) {
        $(this).find('input[type="submit"]').attr('disabled', false).val('Import CSV');

        $('[data-behavior~=view-content]').animate({
          scrollTop: $('[data-behavior~=node-type-validation-message]').scrollTop()
        });
      }

      return valid;
    });

    function validateNodeSelected() {
      var $validationMessage = $('[data-behavior~=node-type-validation-message]');
      $validationMessage.addClass('d-none');

      var selectedEvidenceCount = $('select option[value="evidence"]:selected').length;
      var selectedNodeCount = $('select option[value="node"]:selected').length;

      var valid =  selectedEvidenceCount == 0 ||
                   (selectedEvidenceCount > 0 && selectedNodeCount > 0);

      if (!valid) {
        $validationMessage.removeClass('d-none');
      }

      return valid;
    }
  }

  var setDradisFieldSelect = function($select) {
    var rtpFields = $('[data-behavior=dradis-datatable]').data('rtp-fields');
    if (rtpFields) {
      var fields = rtpFields[$select.val()] || [],
          $fieldSelect = $select.closest('tr').find('[data-behavior=field-select]');

      if (fields.length > 0) {
        $fieldSelect.empty();
        fields.forEach(function(value) {
          $fieldSelect
            .removeAttr('disabled')
            .append(
              $('<option></option>')
              .attr('value', value)
              .text(value)
            );
        });
      } else {
        $fieldSelect
          .attr('disabled', 'disabled')
          .html(
            $('<option selected></option>')
            .attr('value', '')
            .text('N/A')
          );
      }
    }
  }
});
