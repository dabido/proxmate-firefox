{Runtime} = require '../lib/runtime'
{PackageManager} = require '../lib/package-manager'
{ServerManager} = require '../lib/server-manager'
{ProxyManager} = require '../lib/proxy-manager'
{Storage} = require '../lib/storage'
{Browser} = require '../lib/browser'

describe 'Runtime ', ->
  beforeEach ->
    this.sandbox = sinon.sandbox.create()

  afterEach ->
    this.sandbox.restore()

  describe 'start', ->
    it 'should do nothing if no servers are available', ->
      getInstalledPackagesStub = this.sandbox.stub(PackageManager, 'getInstalledPackages', ->
        return [1,2,3]
      )

      getServersStub = this.sandbox.stub(ServerManager, 'getServers', ->
        return []
      )

      storageGetStub = this.sandbox.stub(Storage, 'get', (key) ->
        if key is 'global_status'
          return true
      )

      generatePacStub = this.sandbox.stub(ProxyManager, 'generateProxyAutoconfigScript')
      setPacStub = this.sandbox.stub(ProxyManager, 'setProxyAutoconfig')

      Runtime.start()

      assert.isTrue(getInstalledPackagesStub.calledOnce)
      assert.isTrue(getServersStub.calledOnce)

      assert.isFalse(generatePacStub.calledOnce)
      assert.isFalse(setPacStub.calledOnce)

    it 'should change the badgeText when no packages are available and do nothing', ->
      getInstalledPackagesStub = this.sandbox.stub(PackageManager, 'getInstalledPackages', ->
        return []
      )

      getServersStub = this.sandbox.stub(ServerManager, 'getServers', ->
        return [1,2,3]
      )

      storageGetStub = this.sandbox.stub(Storage, 'get', (key) ->
        if key is 'global_status'
          return true
      )

      generatePacStub = this.sandbox.stub(ProxyManager, 'generateProxyAutoconfigScript')
      setPacStub = this.sandbox.stub(ProxyManager, 'setProxyAutoconfig')
      setBadgeTextStub = this.sandbox.stub(Browser, 'setIcontext')

      Runtime.start()

      assert.isTrue(getInstalledPackagesStub.calledOnce)
      assert.isTrue(getServersStub.calledOnce)

      # Browser text got changed
      assert.isTrue(setBadgeTextStub.calledWith('None'))

      # It shouldn't do anything other than that
      assert.isFalse(generatePacStub.calledOnce)
      assert.isFalse(setPacStub.calledOnce)

    it 'should do nothing and call stop() if global_status is set to false', ->
      getInstalledPackagesStub = this.sandbox.stub(PackageManager, 'getInstalledPackages', ->
        return []
      )

      getServersStub = this.sandbox.stub(ServerManager, 'getServers', ->
        return []
      )

      storageGetStub = this.sandbox.stub(Storage, 'get', (key) ->
        if key is 'global_status'
          return false
      )

      stopStub = this.sandbox.stub(Runtime, 'stop')

      generatePacStub = this.sandbox.stub(ProxyManager, 'generateProxyAutoconfigScript')
      setPacStub = this.sandbox.stub(ProxyManager, 'setProxyAutoconfig')

      Runtime.start()

      assert.isFalse(getInstalledPackagesStub.calledOnce)
      assert.isFalse(getServersStub.calledOnce)

      assert.isFalse(generatePacStub.calledOnce)
      assert.isFalse(setPacStub.calledOnce)

      assert.isTrue(stopStub.calledOnce)


    it 'should generate and set pac if packages and servers are available', ->
      getInstalledPackagesStub = this.sandbox.stub(PackageManager, 'getInstalledPackages', ->
        return [1]
      )

      getServersStub = this.sandbox.stub(ServerManager, 'getServers', ->
        return [1,2,3]
      )

      storageGetStub = this.sandbox.stub(Storage, 'get', (key) ->
        if key is 'global_status'
          return true
      )

      generatePacStub = this.sandbox.stub(ProxyManager, 'generateProxyAutoconfigScript')
      setPacStub = this.sandbox.stub(ProxyManager, 'setProxyAutoconfig')
      chromeBadgeTextStub = this.sandbox.stub(Browser, 'setIcontext')

      Runtime.start()

      assert.isTrue(getInstalledPackagesStub.calledOnce)
      assert.isTrue(getServersStub.calledOnce)
      assert.isTrue(chromeBadgeTextStub.calledWith(""))

      assert.isTrue(generatePacStub.calledOnce)
      assert.isTrue(setPacStub.calledOnce)

    it 'should call start and stop on restart, should reinit server and packagemanger', ->
      stub1 = this.sandbox.stub(Runtime, 'stop')
      stub2 = this.sandbox.stub(Runtime, 'start')
      packageManagerStub = this.sandbox.stub(PackageManager, 'init')
      serverManagerStub = this.sandbox.stub(ServerManager, 'init', (callback) ->
        callback()
      )
      Runtime.restart()

      assert.isTrue(stub1.calledOnce)
      assert.isTrue(stub2.calledOnce)
      assert.isTrue(packageManagerStub.calledOnce)
      assert.isTrue(serverManagerStub.calledOnce)

    it 'should reset the proxy on stop and change icon + text', ->
      clearProxyStub = this.sandbox.stub(ProxyManager, 'clearProxy')
      chromeBadgeTextStub = this.sandbox.stub(Browser, 'setIcontext')
      chromeSetIconStub = this.sandbox.stub(Browser, 'setIcon')

      Runtime.stop()

      assert.isTrue(clearProxyStub.calledOnce)
      assert.isTrue(chromeBadgeTextStub.calledOnce)
      assert.isTrue(chromeSetIconStub.calledOnce)
