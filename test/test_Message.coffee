require 'should'
fs = require 'fs-extra'
path = require 'path'
{
    setUp
    tearDown
} = require './_helpers.coffee'

describe 'Message', ->

    Message = require '../source/Message.coffee'

    it 'should create a new message', (done) ->
        tmp_dir = setUp()
        Message.send
            box     : tmp_dir
            text    : 'Tést\nmessage.'
        .then (message) ->
            fs.existsSync(message._text_path).should.be.true
            fs.readFileSync(message._text_path).toString().should.equal('Tést\nmessage.')
            tearDown(tmp_dir)
            done()

    it 'should load an existing message', (done) ->
        tmp_dir = setUp()
        ts = "2013-07-31-01-22-33-444-Z.txt"
        filename = "#{ ts }.txt"
        message_text_path = path.join(tmp_dir, filename)

        fs.writeFile message_text_path, 'Existing message', (err) ->
            throw err if err?
            message = new Message(message_text_path)
            message.date.getTime().should.equal(1375233753444)
            message.getText().then (text) ->
                text.should.equal('Existing message')
                tearDown(tmp_dir)
                done()

    it.skip 'should create a message with attachments', (done) ->

    it.skip 'should load an existing message with attachments', (done) ->

