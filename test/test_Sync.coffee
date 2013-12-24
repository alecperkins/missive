require 'should'

{ setUp, setUpConfig, tearDown } = require './_helpers.coffee'

# Note: these tests spawn a BitTorrent Sync instance, and may not kill it
# (eg when they fail), so be sure to hunt down stray BTSync processes.

describe 'Sync', ->
    Sync = require '../source/Sync.coffee'
    
    it.skip 'should spawn a BTSync instance', ->
        tmp_dir = setUp()
        config = setUpConfig(tmp_dir)
        sync = new Sync(config)

        sync._btsync_app_instance.should.have.property('pid')
        sync._btsync_app_instance.killed.should.be.false

        tearDown(tmp_dir)

    it.skip 'should provide an empty list of folders', (done) ->
        tmp_dir = setUp()
        config = setUpConfig(tmp_dir)
        sync = new Sync(config)

        sync.getFolders().then (folders) ->
            console.log 'folders'
            folders.length.should.equal(0)
            done()

        # tearDown(tmp_dir)
