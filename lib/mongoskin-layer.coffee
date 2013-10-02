fs = require 'fs'
path = require 'path'

module.exports = (app) ->
  app.sequence('models').add('mongoskin', add_mongoskin(app))
  app.sequence('models').add('create-models', create_models(app))
  
  app.path.models ?= path.join(app.path.app, 'models')
  
  app.models ?= {}

create_models = (app) ->
  (done) ->
    read_dir = (dir) ->
      return unless fs.existsSync(dir)

      for filename in fs.readdirSync(dir)
        file_path = path.join(dir, filename)
        return read_dir(file_path) if fs.statSync(file_path)?.isDirectory()
        read_file(file_path)

    read_file = (file_path) ->
      try
        require(file_path)
      catch err
        err.message = 'Error in ' + file_path + ': ' + err.message
        return callback(err)

    read_dir(app.path.models)
    done()

add_mongoskin = (app) ->
  (done) ->
    return done() unless app.config.mongodb?
  
    mongoskin = null
  
    try
      mongoskin = require 'mongoskin'
    catch err
      if err.code is 'MODULE_NOT_FOUND'
        console.log "Looks like you don't have mongoskin installed yet.\nYou should run\n\nnpm install --save mongoskin\n\nin your project directory."
        return done(err)
      done(err)
  
    app.mongoskin = {connection: mongoskin.db(app.config.mongodb.url)}
    app.Model = require './model'
  
    ['connect', 'disconnect', 'open', 'close', 'error'].forEach (evt) =>
      app.mongoskin.connection.on evt, -> console.log evt, arguments
  
    app.mongoskin.connection.on 'error', (err) ->
      console.log 'ERROR IN MONGOSKIN CONNECTION'
      console.log(err.stack)
  
    console.log 'waiting for mongoskin connection...'
    return done() if app.mongoskin.connection.state is require('mongoskin/lib/mongoskin/constant').STATE_OPEN
    # @mongoskin.connection.on('open', done)
    done()
