jQuery.fn.reverse = [].reverse;

function _init_cluster_tree(idx) {
  const target = $($(this).data('target'));

  function addToTarget(thing) {
    const clone = thing.parent().clone();
    clone.find('input').remove();
    clone.find('ul').removeClass('collapse collapsing')
      .attr('style', '');
    clone.find('button').remove();
    target.append(clone);
  }

  const updateTree = function() {
    target.html('');

    const clusterParts = $(this).find('.cluster-part');

    // Work bottom-up to set parent checkedness
    clusterParts.reverse().each(
      function() {
        const self = $(this);
        const input = self.find('input[type=checkbox]');

        const childList = self.parent().children('ul');

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
          if (input.data('cluster')) {
            self.addClass('selected-cluster');
          }
        }
        else {
          self.removeClass('selected selected-cluster')
        }
      }
    );

    // and top-down to add to target
    clusterParts.reverse().each(
      function() {
        const self = $(this);
        const input = self.find('input[type=checkbox]');

        if (input.is(':checked')) {

          if (input.data('cluster')) {
            addToTarget(self);
            return false;
          }
          else if (self.data('parent')) {
            if (!$(self.data('parent')).is(':checked')) {
              addToTarget(self);
            }
          }
          else {
            addToTarget(self);
          }

        }

      }
    );
  }.bind(this);

  $(this).find('input[type=checkbox]').on(
    'change',
    function() {

      const parentLi = $(this).parents('li').first();

      parentLi.find('ul').find('input[type=checkbox]').prop(
        'checked',
        $(this).prop('checked')
      );

      $(this).prop('indeterminate', false);

      updateTree();
    }
  );

  // Initialise selectedness of children based on their parent
  $(this).find('.cluster-part').each(
    function() {
      const self = $(this);

      const input = self.find('input[type=checkbox]');
      const childList = self.parent().children('ul');
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
  $(this).data('initialised', true);
}

document.addEventListener('turbolinks:load',
  function() {
    $('.cluster-tree').each(
      _init_cluster_tree
    );

    // Allow cluster tree to work within a dropdown
    // https://stackoverflow.com/a/25253002
    $('.dropdown-menu .cluster-tree').on('click', function(event){
      let events = $._data(document, 'events') || {};
      events = events.click || [];
      for(let i = 0; i < events.length; i++) {
        if(events[i].selector) {

          //Check if the clicked element matches the event selector
          if($(event.target).is(events[i].selector)) {
            events[i].handler.call(event.target, event);
          }

          // Check if any of the clicked element parents matches the
          // delegated event selector (Emulating propagation)
          $(event.target).parents(events[i].selector).each(function(){
            events[i].handler.call(this, event);
          });
        }
      }
      event.stopPropagation(); //Always stop propagation
    });
  }
);
