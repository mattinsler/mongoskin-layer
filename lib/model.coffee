q = require 'q'

promise_me = (deferred, callback) ->
  deferred.promise.nodeify(callback)
  
  (err, data) ->
    return deferred.reject(err) if err?
    deferred.resolve(data)

wrap_model = (model, callback) ->
  (err, data) ->
    return callback(err) if err?
    return callback() unless data?
    if Array.isArray(data)
      data = data.map (d) -> new model(d)
    else
      data = new model(data)
    
    callback(null, data)

class Query
  constructor: (@model) ->
    @query = {}
    @opts = {}
  
  where: (query = {}) ->
    @query[k] = v for k, v of query
    @
  
  sort: (sort) ->
    @opts.sort = sort
    @
  
  fields: (fields) ->
    @opts.fields = fields
    @
  
  first: (callback) ->
    d = q.defer()
    @model.__collection__.findOne(@query, @opts, wrap_model(@model, promise_me(d, callback)))
    d.promise
    
  array: (callback) ->
    d = q.defer()
    @model.__collection__.find(@query, @opts).toArray(wrap_model(@model, promise_me(d, callback)))
    d.promise
  
  count: (callback) ->
    d = q.defer()
    @model.__collection__.count(@query, promise_me(d, callback))
    d.promise
  
  update: (update, opts, callback) ->
    if typeof opts is 'function'
      callback = opts
      opts = {}
    
    d = q.defer()
    @model.__collection__.update(@query, update, opts, promise_me(d, callback))
    d.promise
  
  remove: (opts, callback) ->
    if typeof opts is 'function'
      callback = opts
      opts = {}
    
    d = q.defer()
    @model.__collection__.remove(@query, opts, promise_me(d, callback))
    d.promise


class Model
  constructor: (data) ->
    unless @ instanceof Model
      class CollectionModel extends Model
      
      CollectionModel.collection_name = data
      collection = APP.mongoskin.connection.collection(CollectionModel.collection_name)
      CollectionModel::__collection__ = CollectionModel.__collection__ = collection
      
      return CollectionModel
    
    @[k] = v for k, v of data
  
  @where: -> new Query(@).where(arguments...)
  @first: -> @where().first(arguments...)
  @array: -> @where().array(arguments...)
  @count: -> @where().count(arguments...)
  @sort: -> @where().sort(arguments...)
  @skip: -> @where().skip(arguments...)
  @limit: -> @where().limit(arguments...)

  @save: (obj, opts, callback) ->
    if typeof opts is 'function'
      callback = opts
      opts = {}

    d = q.defer()
    @__collection__.save(obj, opts,wrap_model(@, promise_me(d, callback)))
    d.promise
  
  @update: (query, update, opts, callback) -> @where(query).update(update, opts, callback)
  @remove: (query, opts, callback) -> @where(query).remove(opts, callback)

Model.__promise_me = promise_me
Model.ObjectID = APP.mongoskin.connection.ObjectID
module.exports = Model
