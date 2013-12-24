fs      = require 'fs-extra'
path    = require 'path'
crypto  = require 'crypto'

# Detect the user's home in a cross-platform manner. (You'd think node could
# normalize this for us but no.)
HOME_FOLDER = process.env.HOME or process.env.USERPROFILE



# Public: Manager class for handling the app and BTSync configuration.
#         Facilitates creating the necessary `config.json` file for the Sync
#         instance, as well as the folders for message and sync storage.
#         Multiple configs can be used, provided they are given different
#         parent folders to operate in.
#
# parent_folder - (optional: USER HOME) the String absolute path to the parent
#                   directory used to store the `.missive` folder. Defaults to
#                   the user home.
class Config
    PATHS: (home_folder, app_folder) ->
        MISSIVE_ROOT        : path.join(home_folder, app_folder)
        CONFIG_JSON         : path.join(home_folder, app_folder, 'config.json')
        MSG_DATA_FOLDER     : path.join(home_folder, app_folder, 'message_data')
        SYNC_DATA_FOLDER    : path.join(home_folder, app_folder, 'sync_data')
        SYNC_BINARY         : '/Applications/BitTorrent\ Sync.app/Contents/MacOS/BitTorrent\ Sync'

    constructor: (parent_folder=HOME_FOLDER, app_folder='.missive') ->
        @_config = @PATHS(parent_folder, app_folder)
        Object.freeze(@_config)

        # If there is not a `config.json` created, this is the first time the
        # configuration has been initialized for the given parent folder.
        unless fs.existsSync(@_config.CONFIG_JSON)
            @_ensureDirectories()
            @_writeConfig()

        # Load the connection information, which may have been written by a
        # previous session.
        @_loadConnInfo()
        return

    # Internal: Ensure the requisite storage directories have been created.
    #           They will already exist if this configuration has been used
    #           before (typical).
    #
    # Returns nothing.
    _ensureDirectories: ->
        unless fs.existsSync(@_config.MISSIVE_ROOT)
            fs.mkdirSync(@_config.MISSIVE_ROOT)
        unless fs.existsSync(@_config.MSG_DATA_FOLDER)
            fs.mkdirSync(@_config.MSG_DATA_FOLDER)
        unless fs.existsSync(@_config.SYNC_DATA_FOLDER)
            fs.mkdirSync(@_config.SYNC_DATA_FOLDER)

    # Internal: Write the config data to a `config.json` for use by the BTSync
    #           instance. Specifies the host and login information that will
    #           be used for API access.
    #
    # Returns nothing.
    _writeConfig: ->
        fs.writeJSONFileSync @_config.CONFIG_JSON,
            storage_path    : @_config.SYNC_DATA_FOLDER
            use_gui         : false
            webui:
                listen      : '127.0.0.1:8990'
                api_key     : fs.readFileSync(path.join(__dirname, 'apikey')).toString()
                # The login and password aren't particularly sensitive locally,
                # but required by BTSync since it does expose the BTSync
                # service externally.
                login       : 'missive'
                password    : _randomHex()

    # Internal: Load existing API connection information from the `config.json`.
    #           This will be used by the Sync handler to connect to a running
    #           BT Sync instance.
    #
    # Returns nothing.
    _loadConnInfo: ->
        config_obj = fs.readJSONFileSync(@_config.CONFIG_JSON)
        [host, port] = config_obj.webui.listen.split(':')
        @_conn_config =
            host        : host
            port        : port
            username    : config_obj.webui.login
            password    : config_obj.webui.password
            timeout     : 10000

    # Public: Retrieve the full path to the `config.json` file.
    #
    # Returns the String absolute path.
    getConfigPath: -> @_config.CONFIG_JSON

    # Public: Retrieve the full path to the folder for storing message data.
    #         This is the folder where the actual channel information and
    #         message contents are stored.
    #
    # Returns the String absolute path.
    getMessageDataFolder: -> @_config.MSG_DATA_FOLDER

    # Public: Retrieve the full path to the folder for storing sync data.
    #         This folder is used by the BTSync instance to store
    #         information necessary to sync the data (indexes, etc).
    #
    # Returns the String absolute path.
    getSyncDataFolder: -> @_config.SYNC_DATA_FOLDER

    # Public: Retrieve the full path to the platform-specific Sync binary.
    #         (Currently only supports the Mac OS X version of BTSync.)
    #         This is used by the Sync manager to launch a BTSync instance.
    #
    # Returns the String absolute path.
    getBTSyncPath: -> @_config.SYNC_BINARY

    # Public: Retrieve the connection information for this Config's path.
    #
    # Returns the String absolute path.
    getConnConfig: -> @_conn_config



# Internal: Generate some random hex characters for use as the BTSync password.
#
# Returns a 40-character String of hex characters.
_randomHex = ->
    s = crypto.createHash('sha1')
    s.update(crypto.randomBytes(256))
    return s.digest('hex')



module.exports = Config
