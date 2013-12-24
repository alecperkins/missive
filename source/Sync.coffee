###
# Sync

Manages a BitTorrent Sync instance (referred to throughout as "BTSync").
###

BTSync      = require 'bittorrent-sync'
{ spawn }   = require 'child_process'
Q           = require 'q'
fs          = require 'fs'
path        = require 'path'
_           = require 'underscore'



# Public: The manager class that wraps a single instance of BTSync, using
#         Missive-specific configuration. Provides methods for interacting
#         with the instance, translating them to BTSync API calls.
#
# config    - a Config instance that has the necessary connection information.
#
class Sync
    constructor: (config) ->
        @_config = config
        @_spawnInstance()
        @_connectToBTSync()

    # Internal: Spawn the BTSync instance as a child process, using the
    #           `config.json` that was prepared by and specified in the given
    #           Config object.
    #
    # Returns nothing.
    _spawnInstance: ->
        args = [
                '--config'
                @_config.getConfigPath()
            ]
        console.log 'Sync::_spawnInstance', @_config.getBTSyncPath(), @_config.getConfigPath(), args
        @_btsync_app_instance = spawn @_config.getBTSyncPath(), args
        console.log 'spawned', @_btsync_app_instance

    # Internal: Connect to the BTSync API using the BTSync node package and
    #           the Config's connection info.
    #
    # Returns nothing.
    _connectToBTSync: ->
        console.log 'Sync::_connectToBTSync', @_config.getConnConfig()
        @_btsync = new BTSync(@_config.getConnConfig())

    # Public: (ASYNC) get the folders being sync'd by the BTSync instance.
    #
    # Returns a promise that, when fulfilled, will provide a list of folder
    # info.
    getFolders: ->
        console.log 'Sync::getFolders'
        d = Q.defer()
        @_btsync.getFolders (err, data) ->
            throw err if err?
            d.fulfill(data)
            console.log data
        console.log d
        return d.promise

    # Public: (ASYNC) add a folder to be synchronized by the BTSync instance.
    #
    # folder - The String path of the folder, relative to the message data
    #           folder specified by the current Config.
    # secret - (optional: null) The secret key to use for the folder. Used
    #           when adding a folder as an inbox.
    #
    # Returns a promise that, when fulfilled, will provide the added folder's
    # info as an object, including the secrets for that folder.
    # The folder data looks something like:
    #
    #     {
    #         dir: "/Users/username/.missive/message_data/channelname/inbox"
    #         error: 0
    #         files: 0
    #         indexing: 0
    #         secret: "AINQECE4MJEKKNZTXDHJKOQ2AAV4FKSLO"
    #         secrets:
    #             read_only: "BEHUCHDEZM7CSBR4XWRAGRHWEYWLKBB73"
    #             read_write: "AINQECE4MJEKKNZTXDHJKOQ2AAV4FKSLO"
    #         size: 0
    #         type: "read_write"
    #     }
    #
    addFolder: (folder, secret=null) ->
        console.log 'Sync::addFolder', arguments
        d = Q.defer()
        folder = path.join(@_config.getMessageDataFolder(), folder)
        folder_opts =
            dir: folder
        if secret
            folder_opts.secret = secret
        fs.mkdir folder, (err) =>
            throw err if err?
            @_btsync.addFolder folder_opts, (err, data) =>
                throw err if err?
                # Need to re-get the folders because the API is fucking stupid
                # and doesn't return any useful information after adding.
                @_btsync.getFolders (err, folders) =>
                    folder_data = _.find folders, (f) -> f.dir is folder
                    # And naturally we have to do a second call just to get
                    # all the damn secrets. I mean really, WTF. It's not like
                    # this is more secure, just more obnoxious.
                    @_btsync.getSecrets
                        secret: folder_data.secret
                    , (err, secrets) =>
                        folder_data.secrets = secrets
                        d.fulfill(folder_data)
                        console.log folder_data
        return d.promise



module.exports = Sync