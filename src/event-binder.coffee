{Browser} = require './browser'
{PackageManager} = require './package-manager'
{Storage} = require './storage'
{Runtime} = require './runtime'

class EventBinder

  constructor: ->
    @port = null

  init: ->
    {Browser} = require './browser'
    {PackageManager} = require './package-manager'
    {Storage} = require './storage'
    {Runtime} = require './runtime'

    require("sdk/page-mod").PageMod({
        include: /.*proxmate\.me.*/,
        contentScriptFile: [
            require('sdk/self').data.url("bower_components/jquery/dist/jquery.js"),
            require('sdk/self').data.url("src/page-worker/proxmate.js")
        ],
        onAttach: (worker) =>
          @handlePort(worker.port)
    });

    require("sdk/page-mod").PageMod({
        include: /resource\:\/\/@@PACKAGE_FULL_IDENTIFIER\/proxmate\/data\/pages\/install\/index.html.*/,
        contentScriptFile: [
          require('sdk/self').data.url('bower_components/angular/angular.js'),
          require('sdk/self').data.url('bower_components/angular-route/angular-route.js'),
          require('sdk/self').data.url('src/pages/install.js'),
          require('sdk/self').data.url('src/pages/services/chrome.js')
        ],
        onAttach: (worker) =>
          @handlePort(worker.port)
    });

    require("sdk/page-mod").PageMod({
        include: /.*proxmate\/data\/pages\/options\/index.html.*/,
        contentScriptFile: [
          require('sdk/self').data.url('bower_components/angular/angular.js'),
          require('sdk/self').data.url('src/pages/options.js'),
          require('sdk/self').data.url('src/pages/services/chrome.js')
        ],
        onAttach: (worker) =>
          @handlePort(worker.port)
    });

    require("sdk/page-mod").PageMod({
        include: /.*/,
        contentScriptFile: [
          require('sdk/self').data.url('bower_components/jquery/dist/jquery.js'),
          require('sdk/self').data.url('src/page-worker/services/proxmate.js'),
          require('sdk/self').data.url('src/page-worker/proxmatecs.js')
        ],
        onAttach: (worker) =>
          @handlePort(worker.port)
    });


  handlePort: (port) ->
    port.on('installPackage', (payload) ->
      PackageManager.installPackage(payload.packageId, (response) ->
        port.emit(payload.eventId, response)
      )
    )

    port.on('getProxmateGlobalStatus', (payload) ->
      {Storage} = require './storage'
      console.info '---> in proxmate global status'
      console.info this
      console.info Storage
      status = Storage.get('global_status')
      if status
        port.emit(payload.eventId, status)
      else
        port.emit(payload.eventId, false)
    )

    port.on('setProxmateGlobalStatus', (payload) ->
      newStatus = payload.newStatus
      if typeof newStatus != 'boolean'
        newStatus = false

      Storage.set('global_status', newStatus)

      # Start / Stop ProxMate service if neccesary
      if newStatus
        Runtime.start()
      else
        Runtime.stop()

      port.emit(payload.eventId, true)
    )

    port.on('getInstalledPackages', (payload) ->
      packages = PackageManager.getInstalledPackages()
      console.info 'Installed packages before giving back to port'
      console.info packages
      port.emit(payload.eventId, packages)
    )

    port.on('removePackage', (payload) ->
      packageId = payload.packageId
      PackageManager.removePackage(packageId)

      port.emit(payload.eventId, true)
    )

    port.on('getDonationkey', (payload) ->
      key = Storage.get('donation_key')

      port.emit(payload.eventId, key)
    )

    port.on('setDonationkey', (payload) ->
      key = payload.donationKey
      if key?
        Storage.set('donation_key', key)
      else
        Storage.remove('donation_key')

      {Runtime} = require('./runtime')
      Runtime.restart()

      port.emit(payload.eventId, true)
    )

    port.on('getUrlFor', (payload) ->
      console.info "requesting url for #{payload.url}"
      port.emit(payload.eventId, require('sdk/self').data.url(payload.url))
    )

    port.on('openUrl', (payload) =>
      require("sdk/tabs").open(payload.url)
    )

    port.on('xhr', (payload) =>
      console.info 'doing xhr request...'
      console.info "url: #{payload.url}"
      Browser.xhr(payload.url, 'GET', (data) ->
        console.info 'xhr success'
        console.info data
        port.emit(payload.eventId, data)
      , (data) ->
        console.info 'failure'
        console.info data
        port.emit(payload.eventId, data)
      )

    )

exports.EventBinder = new EventBinder()
