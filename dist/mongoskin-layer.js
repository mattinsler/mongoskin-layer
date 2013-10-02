(function() {
  var add_mongoskin, create_models, fs, path;

  fs = require('fs');

  path = require('path');

  module.exports = function(app) {
    var _base, _ref, _ref1;
    app.sequence('models').add('mongoskin', add_mongoskin(app));
    app.sequence('models').add('create-models', create_models(app));
    if ((_ref = (_base = app.path).models) == null) {
      _base.models = path.join(app.path.app, 'models');
    }
    return (_ref1 = app.models) != null ? _ref1 : app.models = {};
  };

  create_models = function(app) {
    return function(done) {
      var read_dir, read_file;
      read_dir = function(dir) {
        var file_path, filename, _i, _len, _ref, _ref1;
        if (!fs.existsSync(dir)) {
          return;
        }
        _ref = fs.readdirSync(dir);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          filename = _ref[_i];
          file_path = path.join(dir, filename);
          if ((_ref1 = fs.statSync(file_path)) != null ? _ref1.isDirectory() : void 0) {
            return read_dir(file_path);
          }
          read_file(file_path);
        }
      };
      read_file = function(file_path) {
        try {
          return require(file_path);
        } catch (err) {
          err.message = 'Error in ' + file_path + ': ' + err.message;
          return callback(err);
        }
      };
      read_dir(app.path.models);
      return done();
    };
  };

  add_mongoskin = function(app) {
    return function(done) {
      var mongoskin,
        _this = this;
      if (app.config.mongodb == null) {
        return done();
      }
      mongoskin = null;
      try {
        mongoskin = require('mongoskin');
      } catch (err) {
        if (err.code === 'MODULE_NOT_FOUND') {
          console.log("Looks like you don't have mongoskin installed yet.\nYou should run\n\nnpm install --save mongoskin\n\nin your project directory.");
          return done(err);
        }
        done(err);
      }
      app.mongoskin = {
        connection: mongoskin.db(app.config.mongodb.url)
      };
      app.Model = require('./model');
      ['connect', 'disconnect', 'open', 'close', 'error'].forEach(function(evt) {
        return app.mongoskin.connection.on(evt, function() {
          return console.log(evt, arguments);
        });
      });
      app.mongoskin.connection.on('error', function(err) {
        console.log('ERROR IN MONGOSKIN CONNECTION');
        return console.log(err.stack);
      });
      console.log('waiting for mongoskin connection...');
      if (app.mongoskin.connection.state === require('mongoskin/lib/mongoskin/constant').STATE_OPEN) {
        return done();
      }
      return done();
    };
  };

}).call(this);
