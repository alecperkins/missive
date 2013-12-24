fs      = require 'fs-extra'
Q       = require 'q'
path    = require 'path'
Message = require './Message.coffee'

CHANNEL_INFO_PATHNAME   = 'channel.json'
INBOX_PATHNAME          = 'inbox'
OUTBOX_PATHNAME         = 'outbox'

# Public: A class that represents a channel, with methods for loading and
#           creating messages.
#
# Channels are simply folders that contain an inbox and/or outbox. Each
# channel is given an arbitrary ID, and has a name and slug (derived from
# the name). This information, as well as the read-only secrets for the
# present inbox or outbox are stored in a `channel.json` stored in the
# channel's folder. The secrets are stored for convenience, as they are also
# retrievable from the BTSync process.
#
#     channel-name/
#         channel.json
#             """
#             {
#                 "id": "<uuid4>",
#                 "name": "Channel Name",
#                 "secrets": {
#                     "inbox": "B456KEY",
#                     "outbox": "B123KEY"
#                 }
#             }
#             """
#         inbox/
#         outbox/
#
#
class Channel
    constructor: ({ root, sync, config }) ->
        @_sync = sync
        @_config = config
        @_paths =
            root    : root
            inbox   : path.join(root, INBOX_PATHNAME)
            outbox  : path.join(root, OUTBOX_PATHNAME)
            info    : path.join(root, CHANNEL_INFO_PATHNAME)
        @_info = fs.readJSONSync(@_paths.info)
        @name = @_info.name
        @slug = @_info.slug

    # Public: Send a new message on this channel with the given text content.
    #
    # kwargs
    #   text - the String text content of the message
    #
    # Returns a promise fulfilled with the new Message.
    sendMessage: ({ text }) =>
        unless @hasOutbox()
            throw new Error("Channel #{ @_info.name } does not have an outbox")
        m = Message.send
            box: @_paths.outbox
            text: text
        return m

    hasInbox: ->
        return @_info.secrets.inbox?

    hasOutbox: ->
        return @_info.secrets.outbox?

    addInbox: (key) =>
        return @_addBox(name: 'inbox', key: key)

    addOutbox: =>
        return @_addBox(name: 'outbox')

    # Internal: Add an inbox or outbox to the channel.
    #
    # kwargs
    #   name - The String name of the folder, MUST be either 'inbox' or 'outbox'
    #   key - (optional: null) The String secret key to use with the folder.
    #           Required if 'inbox', not permitted if 'outbox'.
    #
    # Returns a promise that is fulfilled when the folder has been created
    # and added to the sync process.
    _addBox: ({ name, key }) ->
        d = Q.defer()
        folder = @_paths[name]
        fs.mkdir folder, (err) =>
            throw err if err?
            @_sync.addFolder(folder, key).then (folder_data) =>
                @_info.secrets[name] = folder_data.secrets.read_only
                @_saveChannelInfo()
                d.fulfill()
        return d.promise

    getOutboxMessages: =>
        return @_loadMessagesFor(@_paths.outbox)

    getInboxMessages: =>
        return @_loadMessagesFor(@_paths.inbox)

    # Internal: (ASYNC) Load the messages for the given folder.
    #
    # folder - The String absolute path to a folder of message files.
    #
    # Returns a promise that is fulfilled with an Array of Messages, sorted
    # by reverse chronological order.
    _loadMessagesFor: (folder) ->
        d = Q.defer()
        fs.readdir folder, (err, data) ->
            if err?
                console.log err
                throw err
            messages = data.map (ts) ->
                new Message(path.join(folder, ts))
            messages.sort (a, b) ->
                b.date.getTime() - a.date.getTime()
            d.fulfill(messages)
        return d.promise

    # Internal: Load the `channel.json` data.
    #
    # Returns nothing.
    _loadChannelInfo: ->
        @_info = fs.readJSONSync(@_paths.info)
        return

    # Internal: Update the `channel.json` data from `@_info`.
    #
    # Returns nothing.
    _saveChannelInfo: ->
        fs.writeFileSync(@_paths.info, JSON.stringify(@_info), 'utf-8')
        return

    # Public: create a Channel with a given name. Creates the folder for the
    #           Channel in the data directory, along with a `channel.json`
    #           file that contains the name and secret information.
    #
    # Returns a Channel instance.
    @create = ( { name, config, sync } ) ->
        d = Q.defer()
        channel_info =
            id      : _generateID()
            name    : name
            slug    : _slugify(name)
            secrets :
                inbox   : null
                outbox  : null
        folder_name = "#{ channel_info.id }-#{ channel_info.slug }"
        channel_root = path.join(config.getMessageDataFolder(), folder_name)
        # Create the Channel folder.
        fs.mkdir channel_root, (err, data) ->
            if err?
                console.log err
                throw err
            fs.writeJSONFile path.join(channel_root, CHANNEL_INFO_PATHNAME), channel_info, (err) ->
                if err?
                    console.log err
                    throw err
                channel = new Channel
                    root    : channel_root
                    sync    : sync
                    config  : config
                d.fulfill(channel)
        return d.promise



_slugify = (str) ->
    return str.toLowerCase().replace(/[^a-z0-9]+/g,'_').replace(/(^[\_]+)|([\_]+$)/g,'')

_generateID = ->
    # TODO: replace with UUID
    return (Math.random() * 1000000).toFixed(0).toString()



module.exports = Channel