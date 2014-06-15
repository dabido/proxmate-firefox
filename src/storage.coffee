{Browser} = require './browser'

class Storage
  # Internal array to keep in ram for faster look ups
  constructor: ->
    @internStorage = {}
    @copyInterval = null

  init: (callback) ->
    {Browser} = require './browser'

    @copyFromChromeStorage(=>
      # If global_status is undefined, ProxMate very likely never got started yet.
      # In this case, global_status should be true
      globalStatus = @internStorage['global_status']
      if not globalStatus?
        @internStorage['global_status'] = true
        @copyIntoChromeStorage()

      callback(@internStorage)
    )

  ###*
   * Writes the RAM storage into chrome HDD storage, after a 1 second delay
  ###
  copyIntoChromeStorage: ->
    Browser.clearTimeout @copyInterval
    @copyInterval = Browser.setTimeout(=>
      Browser.writeIntoStorage(@internStorage)
    , 1000)

  copyFromChromeStorage: (callback) ->
    Browser.retrieveFromStorage(null, (object) =>
      @internStorage = object
      callback()
    )

  ###*
   * Deletes all content from RAM storage
  ###
  flush: ->
    @internStorage = {}

  ###*
   * Returns value for 'key' from Storage
   * @return {String|Array} the value inside the storage
  ###
  get: (key) ->
    console.info "Retrieving from storage #{key} - #{@internStorage[key]}"
    return @internStorage[key]

  ###*
   * Sets 'value' for 'key' in storage
  ###
  set: (key, value) ->
    @internStorage[key] = value
    @copyIntoChromeStorage()

  ###*
   * Deletes a key from storage
   * @param  {String} key key to remove
  ###
  remove: (key) ->
    delete @internStorage[key]
    Browser.removeFromStorage(key)
    @copyIntoChromeStorage()

exports.Storage = new Storage()
