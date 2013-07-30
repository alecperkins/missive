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
    <script src="/ui/main.js"></script>
</body>
</html>
"""



express = require 'express'
http    = require 'http'
fs      = require 'fs'

path    = require 'path'

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
    res.write(JSON.stringify(data))
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
        @has_inbox = fs.existsSync(@inbox_folder)
        @has_outbox = fs.existsSync(@outbox_folder)
        @url = "/channels/#{ @name }"
        @messages_url = "/channels/#{ @name }/messages"

    toJSON: =>
        return {
            has_inbox       : @has_inbox
            has_outbox      : @has_outbox
            url             : @url
            messages_url    : @messages_url
            name            : @name
        }

    loadMessages: =>
        messages = []
        if @has_inbox
            inbox_files = fs.readdirSync(@inbox_folder)
            console.log inbox_files
            inbox_files.forEach (f) =>
                if f?[0] isnt '.'
                    messages.push(new Message(@inbox_folder, f))
        if @has_outbox
            outbox_files = fs.readdirSync(@outbox_folder)
            console.log outbox_files
            outbox_files.forEach (f) =>
                if f?[0] isnt '.'
                    messages.push(new Message(@outbox_folder, f))
        messages.sort (a, b) -> b.date - a.date
        return messages



class Message
    constructor: (@box_folder, @name) ->
        console.log @box_folder, @name
        @_path = path.join(@box_folder, @name)
        [orig, year, month, day, hour, minute, second, rest...] = @name.match(/(\d+)-(\d+)-(\d+)T(\d+)-(\d+)-(\d+)Z.txt/)
        @date = new Date("#{ year }-#{ month }-#{ day }T#{ hour }:#{ minute }:#{ second }Z")
    read: ->
        if fs.existsSync(@_path)
            @body = fs.readFileSync(@_path, encoding: 'utf-8')
        return @body
    write: ->
        if @body?
            fs.writeFileSync(@_path, @body, encoding: 'utf-8')
        return
    toJSON: =>
        if not @body?
            @read()
        return {
            box: @box_folder.split(path.sep).pop()
            date: @date.toISOString()
            body: @body
        }
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


app.get '/channels/:channel_name/messages', (req, res) ->
    channel = new Channel(req.params.channel_name)
    messages = channel.loadMessages()
    JSONResponse(res, messages.map( (m) -> m.toJSON() ))

# Create a new message in channel (only works if there is an outbox)
app.post '/channels/:channel_name/messages', (req, res) ->
    channel = new Channel(req.params.channel_name)
    message = Message.create(channel.outbox_folder, req.body.body)
    JSONResponse(res, message.toJSON())




# Start the server
http.createServer(app).listen app.get('port'), ->
    console.log('Express server listening on port ' + app.get('port'))
