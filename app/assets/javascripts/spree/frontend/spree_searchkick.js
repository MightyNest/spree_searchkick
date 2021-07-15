// Placeholder manifest file.
// the installer will append this file to the app vendored assets here: vendor/assets/javascripts/spree/frontend/all.js'
//= require_tree .

$(function () {

  var products = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.whitespace,
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    identify: function(obj) { return obj.id; },
    remote: {
      url: Spree.pathFor('autocomplete/products.json?keywords=%QUERY'),
      wildcard: '%QUERY'
    }
  });

  products.initialize();

  // passing in `null` for the `options` arguments will result in the default
  // options being used
  $('#keywords').typeahead({
      minLength: 2,
      highlight: true,
      limit: 8
    }, {
      name: 'products',
      source: products,
      display: function(obj) {
        return obj.value;
      },
      templates: {
        suggestion: function(obj) {
          if (typeof obj.type === 'undefined' || obj.type == 'item') {
            var result = '<div>' + obj.value;
            if (typeof obj.brand !== 'undefined') {
              result += ' <small>by ' + obj.brand + '</small>';
            }
            return result + '</div>';
          }else if (obj.type == 'taxon') {
            return '<div class="tx">' + obj.value + '</div>';
          }else if (obj.type == 'brand') {
            return '<div class="br">' + obj.value + ' <small>in brands</small></div>';
          }
          return '<div>' + obj.value + '</div>';
        }
      }
    }
  );
  $('#keywords').on('typeahead:open', function() {
    $('.search-container.collapse').addClass('tt-open');
  });
  $('#keywords').on('typeahead:close', function() {
    $('.search-container.collapse').removeClass('tt-open');
  });
  $('#keywords').on('typeahead:select', function(e, data, dataset) {
    if(typeof data.type === 'undefined' || data.type == 'item') {
      window.location = Spree.pathFor('products/' + data.id);
    }else if (data.type == 'brand') {
      window.location = Spree.pathFor('shop/brands/' + data.id);
    }else if (data.type == 'taxon') {
        window.location = Spree.pathFor('t/' + data.id);
    }
  });

});
