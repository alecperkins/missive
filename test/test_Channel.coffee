require 'should'
fs = require 'fs-extra'
Q = require 'q'
path = require 'path'
{
    setUp
    setUpConfig
    tearDown
    MockSync
} = require './_helpers.coffee'

raiseError = (err) ->
    console.log err
    throw new Error(err)

describe 'Channel', ->
    Channel = require '../source/Channel.coffee'

    makeChannel = (done, cb) ->
        tmp_dir = setUp()
        config  = setUpConfig(tmp_dir)
        sync    = new MockSync(config)

        Channel.create
            name    : 'Test Channel'
            config  : config
            sync    : sync
        .then (channel) ->
            if cb?
                cb(channel)
                tearDown(tmp_dir)
                done()
            else
                done channel, ->
                    tearDown(tmp_dir)

    # Sends a batch of messages at least 1ms apart
    class MessageMocker
        constructor: (@_channel) ->
            @_index = 0

        send: (num_to_send) =>
            @_make(@_channel._paths.outbox, num_to_send)

        receive: (num_to_send) =>
            @_make(@_channel._paths.inbox, num_to_send)

        _make: (folder, num_to_send) ->
            [0...num_to_send].forEach =>
                @_index += 1
                f_name = "2013-07-31-13-59-00-12#{ @_index }-Z.txt"
                fs.writeFileSync(path.join(folder, f_name), @_index.toString())
            return

    it 'should create a folder and file', (done) ->
        makeChannel done, (channel) ->
            fs.existsSync(channel._paths.root).should.be.true
            fs.existsSync(channel._paths.info).should.be.true
            channel_info = fs.readJSONFileSync(channel._paths.info)
            channel_info.should.have.property('id')
            channel_info.should.have.property('slug')
            channel_info.should.have.property('secrets')
            channel_info.secrets.should.have.property('inbox')
            channel_info.secrets.should.have.property('outbox')
            channel_info.name.should.equal('Test Channel')
            channel_info.slug.should.equal('test_channel')

    it 'should indicate not having an outbox', (done) ->
        makeChannel done, (channel) ->
            channel.hasOutbox().should.be.false

    it 'should indicate not having an inbox', (done) ->
        makeChannel done, (channel) ->
            channel.hasInbox().should.be.false

    it 'should make an inbox folder', (done) ->
        makeChannel (channel, cb) ->
            channel.addInbox('BDUMMYKEY1234').then ->
                fs.existsSync(channel._paths.inbox).should.be.true
                channel._sync._folders.should.have.length(1)
                channel._sync._folders[0].secrets.read_only.should.equal('BDUMMYKEY1234')
                channel._info.secrets.inbox.should.equal('BDUMMYKEY1234')
                fs.readJSONFileSync(channel._paths.info).secrets.inbox.should.equal('BDUMMYKEY1234')
                channel.hasInbox().should.be.true
            .then(cb)
            .then(done, raiseError)

    it 'should make an outbox folder', (done) ->
        makeChannel (channel, cb) ->
            channel.addOutbox().then ->
                fs.existsSync(channel._paths.outbox).should.be.true
                channel._sync._folders.should.have.length(1)
                channel._sync._folders[0].secrets.read_only.should.equal('BMOCKSECRET1234')
                channel._info.secrets.outbox.should.equal('BMOCKSECRET1234')
                fs.readJSONFileSync(channel._paths.info).secrets.outbox.should.equal('BMOCKSECRET1234')
                channel.hasOutbox().should.be.true
            .then(cb)
            .then(done, raiseError)

    it 'should send messages', (done) ->
        makeChannel (channel, cb) ->
            channel.addOutbox().then ->
                channel.sendMessage
                    text: 'Test message'
                .then (message) ->
                    fs.existsSync(message._text_path).should.be.true
                    fs.readFileSync(message._text_path).toString().should.equal('Test message')
                .then(cb)
                .then(done, raiseError)


    it 'should load outbox messages', (done) ->
        makeChannel (channel, cb) ->
            message_mocker = new MessageMocker(channel)
            channel.addOutbox()
            .then(message_mocker.send(5))
            .then(channel.getOutboxMessages)
            .then (messages) ->
                messages.should.have.length(5)
                last_date = new Date()
                while messages.length > 0
                    this_m = messages.shift()
                    this_m.date.getTime().should.be.below(last_date.getTime())
                    last_date = this_m.date
            .then(cb)
            .then(done, raiseError)



    it 'should load inbox messages', ->
        makeChannel (channel, cb) ->
            message_mocker = new MessageMocker(channel)
            channel.addInbox('BDUMMYKEY1234')
            .then(message_mocker.receive(5))
            .then(channel.getInboxMessages)
            .then (messages) ->
                messages.should.have.length(5)
                last_date = new Date()
                while messages.length > 0
                    this_m = messages.shift()
                    this_m.date.getTime().should.be.below(last_date.getTime())
                    last_date = this_m.date
            .then(cb)
            .then(done, raiseError)

