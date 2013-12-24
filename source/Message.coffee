Q       = require 'q'
fs      = require 'fs'
path    = require 'path'


# Public: A wrapper class that facilitates creating and reading messages.
#
# To create a new message, use `Message.send`:
#
#     Message.send
#         box: '/abs/path/to/message/folder/'
#         text: 'Text message content.'
#
# To load an exising message:
#
#     message = new Message('/path/to/message/timestamp.txt')
#
# The timestamp MUST be in the form:
#
#     <year>-<month>-<day>-<hour>-<minute>-<second>-<millisecond>-Z
#
# (It's not quite an ISO format string, since it has to be a file path.)
class Message
    constructor: (text_path) ->
        @_text_path = text_path
        # Reassemble the timestamp in the filename to proper ISO format.
        [year, month, day, hour, minute, second, millisecond, z] = text_path.split(path.sep).pop().split('-')
        TS = "#{ year }-#{ month }-#{ day }T#{ hour }:#{ minute }:#{ second }.#{ millisecond }Z"
        @date = new Date(TS)

    # Public: (ASYNC) Read the text content of the message.
    #
    # Returns a promise that is fulfilled with the String text content.
    getText: ->
        d = Q.defer()
        fs.readFile @_text_path, (err, data) ->
            throw err if err?
            d.fulfill(data.toString())
        return d.promise

    getAttachments: -> throw new Error('Not implemented')

    # Public: (ASYNC) Create a new message with the given text in the given
    #           folder. "Sends" a message by writing the text content to a
    #           text file named using a timestamp.
    #
    # args - An Object containing the arguments
    #     box   - The String absolute path of the folder to put the message in.
    #     text  - The String text content to save in the message.
    #
    # Returns a promise that is fulfilled with the new Message.
    @send = ({ box, text }) =>
        d = Q.defer()
        filename = "#{ _makeTimestamp() }.txt"
        message_text_path = path.join(box, filename)
        fs.writeFile message_text_path, text, 'utf-8', (err) ->
            throw err if err?
            message = new Message(message_text_path)
            d.fulfill(message)
        return d.promise



_makeTimestamp = ->
    t = new Date()
    # 0-padding, to aid sorting of filenames.
    _pad = (v) ->
        if v < 10
            return "0#{ v.toString() }"
        return v.toString()
    ts = "#{ t.getUTCFullYear() }-#{ _pad(t.getUTCMonth() + 1) }-#{ _pad(t.getUTCDate()) }-#{ _pad(t.getUTCHours()) }-#{ _pad(t.getUTCMinutes()) }-#{ _pad(t.getUTCSeconds()) }-#{ t.getUTCMilliseconds() }-Z"
    return ts



module.exports = Message