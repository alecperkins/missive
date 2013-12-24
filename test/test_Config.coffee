require 'should'
fs = require 'fs-extra'
{ setUp, tearDown } = require './_helpers.coffee'


describe 'Config', ->
    Config = require '../source/Config.coffee'

    CONFIG_KEYS = [
        'MISSIVE_ROOT'
        'CONFIG_JSON'
        'MSG_DATA_FOLDER'
        'SYNC_DATA_FOLDER'
    ]

        
    # TODO: use beforeEach, afterEach for setup/teardown

    it 'should ensure directories', ->
        tmp_dir = setUp()
        config = new Config(tmp_dir)

        CONFIG_KEYS.forEach (k) ->
            fs.existsSync(config._config[k]).should.be.true

        tearDown(tmp_dir)

    it 'should still ensure directories', ->
        tmp_dir = setUp()

        do ->
            # Create the Config instance to ensure the directories once.
            new Config(tmp_dir)

        # Then create it again using the same directories.
        config = new Config(tmp_dir)
        CONFIG_KEYS.forEach (k) ->
            fs.existsSync(config._config[k]).should.be.true

        tearDown(tmp_dir)

    it 'should provide access to info', ->
        tmp_dir = setUp()

        # Then create it again using the same directories.
        config = new Config(tmp_dir)

        config.getConfigPath().should.equal(config._config.CONFIG_JSON)
        config.getMessageDataFolder().should.equal(config._config.MSG_DATA_FOLDER)
        config.getSyncDataFolder().should.equal(config._config.SYNC_DATA_FOLDER)
        config.getBTSyncPath().should.equal(config._config.SYNC_BINARY)
        config.getConnConfig().should.eql(config._conn_config)

        tearDown(tmp_dir)


    it 'should create a config.json', ->
        tmp_dir = setUp()

        # Then create it again using the same directories.
        config = new Config(tmp_dir)

        config_json = fs.readJSONFileSync(config.getConfigPath())

        config_json.storage_path.should.equal(config.getSyncDataFolder())
        config_json.use_gui.should.be.false
        ['listen', 'login', 'password', 'api_key'].forEach (prop) ->
            config_json.webui.should.have.property(prop)

        tearDown(tmp_dir)



