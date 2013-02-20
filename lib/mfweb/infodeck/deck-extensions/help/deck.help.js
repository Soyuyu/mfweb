/*
This module adds a help panel to the deck
*/

(function($, deck, undefined) {
	  var $d = $(document);

  /*
  Extends defaults/options

  options.classes.deck-help-visible
    This option is added to the help panel to make it visible. 

  options.selectors.help 
    The elements that match this selector will toggle the visibility
    of the help panel when clicked.

  options.selectors.help-panel 
    The elements that match this selector will act as a help panel
    which can be made visible by clicking the deck-help elements.
  */

	$.extend(true, $[deck].defaults, {
		classes: {
			helpVisible: 'deck-help-visible'
		},
		
		selectors: {
			helpPanel: '.deck-help-panel',
			help: '.deck-help'
		}
	});

	$d.bind('deck.init', function() {
		  var opts = $[deck]('getOptions');
    $(opts.selectors.help)
       .bind('click', function(e) {
         $(opts.selectors.helpPanel).toggleClass(opts.classes.helpVisible);
       });
  })
})(jQuery, 'deck');