function _init_cluster_tree(idx) {
  const target = $($(this).data('target'));

  function addToTarget(thing) {
    const clone = thing.parent().clone();
    clone.find('input').remove();
    target.append(clone);
  }

  const updateTree = function() {
    target.html('');
    $(this).find('.cluster-part').each(
      function() {
        const self = $(this);
        const input = self.find('input[type=checkbox]');
        if (input.is(':checked')) {
          self.addClass('selected');

          if (self.data('parent')) {
            if (!$(self.data('parent')).is(':checked')) {
              addToTarget(self);
            }
          }
          else {
            addToTarget(self);
          }


        }
        else {
          self.removeClass('selected');
        }
      }
    )
  }.bind(this);

  $(this).find('input[type=checkbox]').on(
    'click',
    function() {

      const parentLi = $(this).parents('li').first();

      parentLi.find('ul').find('input[type=checkbox]').prop(
        'checked',
        $(this).prop('checked')
      );

      updateTree();
    }
  );
  updateTree();
}

$(document).ready(
  function() {
    $('.cluster-tree').each(
      _init_cluster_tree
    );
  }
);
