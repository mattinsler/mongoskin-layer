(function() {
  var Model, Query, promise_me, q, wrap_model,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  q = require('q');

  promise_me = function(deferred, callback) {
    deferred.promise.nodeify(callback);
    return function(err, data) {
      if (err != null) {
        return deferred.reject(err);
      }
      return deferred.resolve(data);
    };
  };

  wrap_model = function(model, callback) {
    return function(err, data) {
      if (err != null) {
        return callback(err);
      }
      if (data == null) {
        return callback();
      }
      if (Array.isArray(data)) {
        data = data.map(function(d) {
          return new model(d);
        });
      } else {
        data = new model(data);
      }
      return callback(null, data);
    };
  };

  Query = (function() {

    function Query(model) {
      this.model = model;
      this.query = {};
      this.opts = {};
    }

    Query.prototype.where = function(query) {
      var k, v;
      if (query == null) {
        query = {};
      }
      for (k in query) {
        v = query[k];
        this.query[k] = v;
      }
      return this;
    };

    Query.prototype.sort = function(sort) {
      this.opts.sort = sort;
      return this;
    };

    Query.prototype.skip = function(skip) {
      this.opts.skip = skip;
      return this;
    };

    Query.prototype.limit = function(limit) {
      this.opts.limit = limit;
      return this;
    };

    Query.prototype.fields = function(fields) {
      this.opts.fields = fields;
      return this;
    };

    Query.prototype.first = function(callback) {
      var d;
      d = q.defer();
      this.model.__collection__.findOne(this.query, this.opts, wrap_model(this.model, promise_me(d, callback)));
      return d.promise;
    };

    Query.prototype.array = function(callback) {
      var d;
      d = q.defer();
      this.model.__collection__.find(this.query, this.opts).toArray(wrap_model(this.model, promise_me(d, callback)));
      return d.promise;
    };

    Query.prototype.count = function(callback) {
      var d;
      d = q.defer();
      this.model.__collection__.count(this.query, promise_me(d, callback));
      return d.promise;
    };

    Query.prototype.save = function(obj, opts, callback) {
      var d, k, v, _ref;
      if (typeof obj === 'function') {
        callback = obj;
        opts = {};
        obj = {};
      }
      if (typeof opts === 'function') {
        callback = opts;
        opts = {};
      }
      _ref = this.query;
      for (k in _ref) {
        v = _ref[k];
        obj[k] = v;
      }
      d = q.defer();
      this.__collection__.save(obj, opts, wrap_model(this, promise_me(d, callback)));
      return d.promise;
    };

    Query.prototype.update = function(update, opts, callback) {
      var d;
      if (typeof opts === 'function') {
        callback = opts;
        opts = {};
      }
      d = q.defer();
      this.model.__collection__.update(this.query, update, opts, promise_me(d, callback));
      return d.promise;
    };

    Query.prototype.remove = function(opts, callback) {
      var d;
      if (typeof opts === 'function') {
        callback = opts;
        opts = {};
      }
      d = q.defer();
      this.model.__collection__.remove(this.query, opts, promise_me(d, callback));
      return d.promise;
    };

    return Query;

  })();

  Model = (function() {

    function Model(data) {
      var CollectionModel, collection, k, v;
      if (!(this instanceof Model)) {
        CollectionModel = (function(_super) {

          __extends(CollectionModel, _super);

          function CollectionModel() {
            return CollectionModel.__super__.constructor.apply(this, arguments);
          }

          return CollectionModel;

        })(Model);
        CollectionModel.collection_name = data;
        collection = APP.mongoskin.connection.collection(CollectionModel.collection_name);
        CollectionModel.prototype.__collection__ = CollectionModel.__collection__ = collection;
        return CollectionModel;
      }
      for (k in data) {
        v = data[k];
        this[k] = v;
      }
    }

    Model.where = function() {
      var _ref;
      return (_ref = new Query(this)).where.apply(_ref, arguments);
    };

    Model.sort = function() {
      var _ref;
      return (_ref = this.where()).sort.apply(_ref, arguments);
    };

    Model.skip = function() {
      var _ref;
      return (_ref = this.where()).skip.apply(_ref, arguments);
    };

    Model.limit = function() {
      var _ref;
      return (_ref = this.where()).limit.apply(_ref, arguments);
    };

    Model.fields = function() {
      var _ref;
      return (_ref = this.where()).fields.apply(_ref, arguments);
    };

    Model.first = function() {
      var _ref;
      return (_ref = this.where()).first.apply(_ref, arguments);
    };

    Model.array = function() {
      var _ref;
      return (_ref = this.where()).array.apply(_ref, arguments);
    };

    Model.count = function() {
      var _ref;
      return (_ref = this.where()).count.apply(_ref, arguments);
    };

    Model.save = function(obj, opts, callback) {
      return this.where().save(obj, opts, callback);
    };

    Model.update = function(query, update, opts, callback) {
      return this.where(query).update(update, opts, callback);
    };

    Model.remove = function(query, opts, callback) {
      return this.where(query).remove(opts, callback);
    };

    return Model;

  })();

  Model.__promise_me = promise_me;

  Model.ObjectID = APP.mongoskin.connection.ObjectID;

  module.exports = Model;

}).call(this);
