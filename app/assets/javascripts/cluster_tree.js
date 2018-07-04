function _init_cluster_tree(idx) {
  const target = $($(this).data('target'));

  const updateTree = function() {
    target.html('');
    $(this).find('.cluster-part').each(
      function() {
        const self = $(this);
        const input = self.find('input[type=checkbox]');
        if (input.is(':checked')) {
          self.addClass('selected');

          const clone = self.parent().clone();
          clone.find('input').remove();
          target.append(clone);
        }
        else {
          self.removeClass('selected');
        }
      }
    )
  }.bind(this);

  $(this).find('input[type=checkbox]').on('change', updateTree);
  updateTree();
}

$(document).ready(
  function() {
    $('.cluster-tree').each(
      _init_cluster_tree
    );
  }
);
