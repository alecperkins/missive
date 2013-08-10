index_file_content = """
<!DOCTYPE html>
<html>
<head>
    <title>Missive</title>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <link href="/ui/doodad-0.0.0-dev.css" type="text/css" rel="stylesheet">
    <link href="/ui/main.css" type="text/css" rel="stylesheet">
</head>
<body>
    <div id="app">Loading&hellip;</div>
    <script src="/ui/zepto-1.0.js"></script>
    <script src="/ui/underscore-1.5.1.js"></script>
    <script src="/ui/backbone-1.0.0.js"></script>
    <script src="/ui/doodad-0.0.0-dev.js"></script>
    <script src="/ui/markdown.js"></script>
    <script src="/ui/date.extensions.js"></script>
    <script src="/ui/main.js"></script>
</body>
</html>
"""



express = require 'express'
http    = require 'http'
fs      = require 'fs'

path    = require 'path'
mime    = require 'mime'

app = express()

app.set('port', process.env.PORT || 3000)

app.use(express.logger('dev'))
app.use(express.bodyParser())
app.use(express.methodOverride())
app.use(app.router)

app.use('/ui', express.static(path.join(__dirname, '../ui')))

if app.get('env') is 'development'
    app.use(express.errorHandler())




JSONResponse = (res, data) ->
    unless data?
        raise404(res)
    res.write(JSON.stringify(data))
    res.end()

BlobResponse = (res, file_info) ->
    unless file_info?
        raise404(res)

    [file_path, file_content] = file_info
    res.write(file_content)
    res.end()

raise404 = (res) ->
    res.status(404)
    res.write('404 NOT FOUND')
    res.end()



app.get '/', (req, res) ->
    res.write(index_file_content)
    res.end()



# Data helpers

DATA_FOLDER = path.join(process.env.HOME, 'missive_data')



class Channel
    constructor: (@name) ->
        @inbox_folder = path.join(DATA_FOLDER, @name, 'inbox')
        @outbox_folder = path.join(DATA_FOLDER, @name, 'outbox')
        @inbox_count = @_countBox(@inbox_folder)
        @outbox_count = @_countBox(@outbox_folder)
        @url = "/channels/#{ @name }"
        @messages_url = "/channels/#{ @name }/messages"

    boxURL: (box) =>
        return "/channels/#{ @name }/#{ box }"

    toJSON: =>
        data = {
            url             : @url
            messages_url    : @messages_url
            name            : @name
        }
        if @inbox_count?
            data.inbox_count    = @inbox_count
            data.inbox_url      = @boxURL('inbox')
        if @outbox_count?
            data.outbox_count    = @outbox_count
            data.outbox_url      = @boxURL('outbox')
        return data


    loadMessage: (box, message_id) ->
        box_folder = @["#{ box }_folder"]
        message_file = message_id + '.txt'
        message_path = path.join(box_folder, message_file)
        if fs.existsSync(message_path)
            return new Message(this, box_folder, message_file)
        return null

    loadMessages: (box=null) =>
        if not @inbox_count? and box is 'inbox'
            return null
        if not @outbox_count? and box is 'outbox'
            return null
        messages = []
        if @inbox_count? and box isnt 'outbox'
            inbox_files = fs.readdirSync(@inbox_folder)
            console.log inbox_files
            inbox_files.forEach (f) =>
                if f?[0] isnt '.'
                    console.log 'f', f.split('.')
                    if f.split('.').length isnt 1
                        messages.push(new Message(this, @inbox_folder, f))
        if @outbox_count? and box isnt 'inbox'
            outbox_files = fs.readdirSync(@outbox_folder)
            console.log outbox_files
            outbox_files.forEach (f) =>
                if f?[0] isnt '.'
                    console.log 'f', f.split('.')
                    if f.split('.').length isnt 1
                        messages.push(new Message(this, @outbox_folder, f))

        messages.sort (a, b) -> b.date - a.date
        return messages

    _countBox: (box_folder) ->
        if not fs.existsSync(box_folder)
            return null
        box_files = fs.readdirSync(box_folder)
        # Don't count hidden files/folders, or folders at all
        # (assumes the folders don't include a . in the path name)
        box_files = box_files.filter (f, i) -> f?[0] isnt '.' and f.split('.').length > 1
        return box_files.length

class Message
    constructor: (@channel, @box_folder, @name) ->
        console.log @channel, @box_folder, @name

        @_path = path.join(@box_folder, @name)
        @id = @name.split('.')[0]
        @_box = @box_folder.split(path.sep).pop()
        @_url = "#{ @channel.boxURL(@_box) }/#{ @id }"
        @_attachments_url = @_url + '/attachments'
        @_attachment_path = path.join(@box_folder, @id)

        [orig, year, month, day, hour, minute, second, rest...] = @name.match(/(\d+)-(\d+)-(\d+)T(\d+)-(\d+)-(\d+)Z.txt/)
        @date = new Date("#{ year }-#{ month }-#{ day }T#{ hour }:#{ minute }:#{ second }Z")

    read: ->
        if fs.existsSync(@_path)
            @body = fs.readFileSync(@_path, encoding: 'utf-8')
            @_has_attachments = fs.existsSync(@_attachment_path)
        return @body
    write: ->
        if @body?
            fs.writeFileSync(@_path, @body, encoding: 'utf-8')
        return

    toJSON: =>
        if not @body?
            @read()
        @_box
        data = {
            box             : @_box
            date            : @date.toISOString()
            body            : @body
            url             : @_url
        }
        if @_has_attachments
            data.attachments_url = @_attachments_url
        return data

    @create = (box_folder, body) ->
        _pad = (n) ->
            if n < 10
                return "0#{ n }"
            return "#{ n }"
        now = new Date()
        year    = now.getUTCFullYear()
        month   = _pad(now.getUTCMonth() + 1)
        day     = _pad(now.getUTCDate())
        hour    = _pad(now.getUTCHours())
        minute  = _pad(now.getUTCMinutes())
        second  = _pad(now.getUTCSeconds())
        name = "#{ year }-#{ month }-#{ day }T#{ hour }-#{ minute }-#{ second }Z.txt"
        message = new Message(box_folder, name)
        message.body = body
        message.write()
        return message

    loadAttachments: ->
        attachments = []
        unless fs.existsSync(@_attachment_path)
            return []

        files = fs.readdirSync(@_attachment_path).filter (f) -> f?[0] isnt '.'
        return files.map (f) => {
                'name': f
                'type': mime.lookup(f)
                'url': @_attachments_url + '/' + f
            }

    loadAttachmentData: (file_path) ->
        target_file = path.join(@_attachment_path, file_path)
        unless fs.existsSync(target_file)
            return null
        return [file_path, fs.readFileSync(target_file)]





discoverChannels = ->
    files = fs.readdirSync(DATA_FOLDER)
    channels = []
    for name in files
        unless name[0] is '.'
            channels.push(new Channel(name))
    return channels

# API Endpoints

app.get '/channels', (req, res) ->
    channels = discoverChannels()
    JSONResponse(res, channels.map( (c) -> c.toJSON() ))

app.get '/channels/:channel_name', (req, res) ->
    channel = new Channel(req.params.channel_name)
    JSONResponse(res, channel.toJSON())


app.get '/channels/:channel_name/:box', (req, res) ->
    channel = new Channel(req.params.channel_name)
    if req.params.box is 'messages'
        box = null
    else
        box = req.params.box
    messages = channel.loadMessages(box)
    JSONResponse(res, messages?.map( (m) -> m.toJSON() ))

app.get '/channels/:channel_name/:box/:message_id', (req, res) ->
    channel = new Channel(req.params.channel_name)
    message = channel.loadMessage(req.params.box, req.params.message_id)
    JSONResponse(res, message?.toJSON() )


app.get '/channels/:channel_name/:box/:message_id/attachments', (req, res) ->
    channel = new Channel(req.params.channel_name)
    message = channel.loadMessage(req.params.box, req.params.message_id)
    JSONResponse(res, message?.loadAttachments() )

app.get '/channels/:channel_name/:box/:message_id/attachments/:attachment_path', (req, res) ->
    channel = new Channel(req.params.channel_name)
    message = channel.loadMessage(req.params.box, req.params.message_id)
    BlobResponse(res, message?.loadAttachmentData(req.params.attachment_path) )


# Create a new message in channel (only works if there is an outbox)
app.post '/channels/:channel_name/messages', (req, res) ->
    channel = new Channel(req.params.channel_name)
    message = Message.create(channel.outbox_folder, req.body.body)
    JSONResponse(res, message?.toJSON())




# Start the server
http.createServer(app).listen app.get('port'), ->
    console.log('Express server listening on port ' + app.get('port'))
