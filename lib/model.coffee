q = require 'q'

promise_me = (deferred, callback) ->
  deferred.promise.nodeify(callback)
  
  (err, data) ->
    return deferred.reject(err) if err?
    deferred.resolve(data)

class Model
  constructor: (data) ->
    unless @ instanceof Model
      class CollectionModel extends Model

      CollectionModel.collection_name = data
      collection = APP.mongoskin.connection.collection(CollectionModel.collection_name)
      CollectionModel::__collection__ = CollectionModel.__collection__ = collection

      return CollectionModel

    @[k] = v for k, v of data

  @wrapper: (model) ->
    (data) ->
      return null unless data?
      if Array.isArray(data)
        data = data.map (d) -> new model(d)
      else
        new model(data)

  @wrap_callback: (model, callback) ->
    wrapper = Model.wrapper(model)
    (err, data) ->
      return callback?(err) if err?
      callback?(null, wrapper(data))

  @defer: (method) ->
    ->
      d = q.defer()
      args = Array::slice.call(arguments)
      callback = args.pop() if typeof args[args.length - 1] is 'function'

      done = (err, results...) ->
        if err?
          d.reject(err)
          callback?(err)
          return

        d.resolve(results...)
        callback?(null, results...)

      result = method.call(@, args..., done)
      if q.isPromise(result)
        result.then(done.bind(null)).catch(done)

      d.promise

  @where: -> new @Query(@).where(arguments...)

  @sort: -> @where().sort(arguments...)
  @skip: -> @where().skip(arguments...)
  @limit: -> @where().limit(arguments...)
  @fields: -> @where().fields(arguments...)

  @first: -> @where().first(arguments...)
  @array: -> @where().array(arguments...)
  @count: -> @where().count(arguments...)

  @save: (obj, opts, callback) -> @where().save(obj, opts, callback)
  @update: (query, update, opts, callback) -> @where(query).update(update, opts, callback)
  @remove: (query, opts, callback) -> @where(query).remove(opts, callback)

  @find_and_modify: Model.defer (query, sort, update, opts, callback) ->
    if typeof opts is 'function'
      callback = opts
      opts = {}

    @__collection__.findAndModify(query, sort, update, opts, promise_me(d, callback))

class Model.Query
  constructor: (@model) ->
    @query = {}
    @opts = {}
  
  where: (query = {}) ->
    @query[k] = v for k, v of query
    @
  
  sort: (sort) ->
    @opts.sort = sort
    @
  
  skip: (skip) ->
    @opts.skip = skip
    @
  
  limit: (limit) ->
    @opts.limit = limit
    @
  
  fields: (fields) ->
    @opts.fields = fields
    @
  
  first: Model.defer (callback) ->
    @model.__collection__.findOne(@query, @opts, Model.wrap_callback(@model, callback))
    
  array: Model.defer (callback) ->
    @model.__collection__.find(@query, @opts).toArray(Model.wrap_callback(@model, callback))
  
  count: Model.defer (callback) ->
    @model.__collection__.count(@query, promise_me(d, callback))
  
  save: Model.defer (obj, opts, callback) ->
    if typeof obj is 'function'
      callback = obj
      opts = {}
      obj = {}
    if typeof opts is 'function'
      callback = opts
      opts = {}
    
    save_obj = {}
    save_obj[k] = v for k, v of obj when not Object.getOwnPropertyDescriptor(obj, k).get?
    save_obj[k] = v for k, v of @query when not Object.getOwnPropertyDescriptor(@query, k).get?
    
    @model.__collection__.save(save_obj, opts, Model.wrap_callback(@model, callback))
  
  update: Model.defer (update, opts, callback) ->
    if typeof opts is 'function'
      callback = opts
      opts = {}
    
    @model.__collection__.update(@query, update, opts, promise_me(d, callback))
  
  remove: Model.defer (opts, callback) ->
    if typeof opts is 'function'
      callback = opts
      opts = {}
    
    @model.__collection__.remove(@query, opts, promise_me(d, callback))



Model.__promise_me = promise_me
Model.ObjectID = APP.mongoskin.connection.ObjectID
module.exports = Model
