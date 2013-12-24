Q   = require 'q'
fs  = require 'fs-extra'
path = require 'path'
_ = require 'underscore'

Config = require '../source/Config.coffee'


test_batch_i = 0


setUpConfig = (tmp_dir) -> return new Config(tmp_dir, 'dotmissive')

# Set up a unique homefolder for each test so they can run concurrently.
setUp = ->
    test_batch_i += 1
    tmp_dir = "/tmp/missive__#{ test_batch_i }__#{ (new Date()).getTime().toString() }/"
    fs.mkdirpSync(tmp_dir)
    return tmp_dir


tearDown = (tmp_dir) ->
    # tmp_dir will be full, so completely remove
    fs.removeSync(tmp_dir)

# Pretends to be a Sync instance, creating the necessary folders and
# responding appropriately, but does not actually have a BTSync process.
class MockSync
    constructor: (@_config) ->
        @_folders = []

    getFolders: ->
        d = Q.defer()
        _.defer ->
            d.fulfill(@_folders)
        return d.promise

    addFolder: (folder, secret=null) ->
        d = Q.defer()
        folder = path.join(@_config.getMessageDataFolder(), folder)
        fs.mkdir folder, (err) =>
            folder_info =
                secrets : {}
                dir     : folder
                files   : 0
            unless secret
                secret = 'BMOCKSECRET1234'
            folder_info.secrets.read_only = secret
            @_folders.push(folder_info)
            d.fulfill(folder_info)
        return d.promise


module.exports =
    MockSync    : MockSync
    setUp       : setUp
    setUpConfig : setUpConfig
    tearDown    : tearDown


