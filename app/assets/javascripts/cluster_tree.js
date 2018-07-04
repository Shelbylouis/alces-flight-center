function _init_cluster_tree(idx) {
  const target = $($(this).data('target'));

  function addToTarget(thing) {
    const clone = thing.parent().clone();
    clone.find('input').remove();
    clone.find('ul').removeClass('collapse collapsing');
    clone.find('button').remove();
    target.append(clone);
  }

  const updateTree = function() {
    target.html('');
    $(this).find('.cluster-part').each(
      function() {
        const self = $(this);
        const input = self.find('input[type=checkbox]');

        const childList = self.parent().find('ul');

        const selectedChildren = childList.find('input:checked').length;
        const allChildren = childList.find('input').length;

        if (allChildren > 0) {
          if (selectedChildren === allChildren) {
            input.prop('checked', true);
            input.prop('indeterminate', false);
          }
          else if (selectedChildren > 0) {
            input.prop('checked', false);
            input.prop('indeterminate', true);
          }
          else {
            input.prop('checked', false);
            input.prop('indeterminate', false);
          }
        }

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

  // Initialise selectedness of children based on their parent
  $(this).find('.cluster-part').each(
    function() {
      const self = $(this);

      const input = self.find('input[type=checkbox]');
      const childList = self.parent().find('ul');
      if (input.is(':checked')) {
        const allChildren = childList.find('input');
        allChildren.prop('checked', true);
      }

      if (childList.find('input:checked').length > 0) {
        childList.collapse('show');
      }
      else if (childList.length > 0) {
        childList.collapse('hide');
      }
    }
  );

  updateTree();
}

document.addEventListener('turbolinks:load',
  function() {
    $('.cluster-tree').each(
      _init_cluster_tree
    );
  }
);
