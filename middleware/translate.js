
var check = require('check-types');
var _ = require('lodash');
var logger = require('pelias-logger').get('api:middleware:translate');

var translations = {};

function setup() {
  var api = require('pelias-config').generate().api;
  var localization = api.localization;
  if (localization) {
    if (localization.translations) {
      translations = require(localization.translations);
    }
  }
  return translate;
}

function translateName(place, lang) {
  if( place.name ) {
    if( place.name[lang] ) {
      place.name = place.name[lang];
    } else if (place.name.default) { // fallback
      place.name = place.name.default;
    }
  }
}

function translateProperties(place, key, names) {
  if( place[key] !== null ) {
    var name;
    if (place[key] instanceof Array) {
      name = place[key][0];
      if (name && names[name]) {
        place[key][0] = names[name]; // do the translation
      }
    } else {
      name = place[key];
      if (name && names[name]) {
        place[key] = names[name];
      }
    }
  }
}

function translate(req, res, next) {

  // do nothing if no result data set
  if (!res || !res.data) {
    return next();
  }

  var lang, matched;
  if (req.clean) {
    lang = req.clean.lang;
  }

  if( lang && translations[lang] ) {
    _.forEach(translations[lang], function(names, key) {
      _.forEach(res.data, function(place) {
        translateProperties(place, key, names);
        translateProperties(place.parent, key, names);
        if(place.address_parts) {
          translateProperties(place.address_parts, key, names);
        }
      });
    });
  }

  _.forEach(res.data, function(place) {
    translateName(place, lang);
  });

  next();
}

module.exports = setup;
