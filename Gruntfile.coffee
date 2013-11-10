path = require 'path'

module.exports = (grunt) ->

    PACKAGE             = grunt.file.readJSON('./package.json')
    DEBUG               = not grunt.cli.options.production
    BUILD_DIR           = './build/'
    DIST_DIR            = './dist/'
    SOURCE_DIR          = './source/'
    WATCH_TARGET_DIR    = path.join(DIST_DIR,'releases',PACKAGE.name,'mac',"#{ PACKAGE.name }.app",'Contents','Resources','app.nw')

    grunt.initConfig
        pkg: PACKAGE

        nodewebkit:
            # Build the node-webkit app.
            options:
                build_dir   : DIST_DIR
                mac         : true
                win         : false
                linux32     : false
                linux64     : false
            src: ["#{ BUILD_DIR }**/*"]

        coffee:
            # Compile the .coffee files into the build folder, to be zipped
            # into the app.nw package.
            compile:
                options:
                    sourceMap: DEBUG
                files: [
                    expand  : true
                    cwd     : SOURCE_DIR
                    src     : ['**/*.coffee']
                    dest    : BUILD_DIR
                    ext     : '.js'
                ]
            watch:
                # Compile the .coffee files, placing them inside the .app
                # package instead of the build folder.
                options:
                    sourceMap: DEBUG
                files: [
                    expand  : true
                    cwd     : SOURCE_DIR
                    src     : ['**/*.coffee']
                    dest    : WATCH_TARGET_DIR
                    ext     : '.js'
                ]

        watch:
            # Watch for changes to .coffee files.
            files: SOURCE_DIR + '**/*.coffee'
            tasks: ['coffee:watch']

        copy:
            # Copy non-coffee files to the build directory for packaging into
            # an app by the node-webkit builder.
            forbuild:
                expand  : true
                cwd     : SOURCE_DIR
                src     : ['**/*']
                dest    : BUILD_DIR
                filter  : (f_name) ->
                    return f_name.split('.').pop() isnt 'coffee'

            # Copies the files to the .app package contents for dev purposes.
            forwatch:
                expand  : true
                cwd     : BUILD_DIR
                src     : ['**/*']
                dest    : WATCH_TARGET_DIR

    grunt.loadNpmTasks('grunt-node-webkit-builder')
    grunt.loadNpmTasks('grunt-contrib-coffee')
    grunt.loadNpmTasks('grunt-contrib-copy')
    grunt.loadNpmTasks('grunt-contrib-watch')

    # Generate the package.json to be used for building the .app file. Not
    # just a copy of the main package.json, for stricter control of its contents.
    grunt.registerTask 'writepackagejson', '', ->
        source_package = grunt.config.get('pkg')
        dist_package = {}
        for k in ['name','version','website','description','dependencies','license','webkit','window']
            dist_package[k] = source_package[k]
        dist_package.main = 'index.html'
        grunt.file.write("#{ BUILD_DIR }package.json", JSON.stringify(dist_package))

    # Convert the app.nw zip file to a folder, for watch-based compiling.
    grunt.registerTask 'preparewatch', '', ->
        grunt.file.delete(WATCH_TARGET_DIR)
        grunt.file.mkdir(WATCH_TARGET_DIR)

    # Clear out older builds.
    grunt.registerTask 'prebuild', '', ->
        for f in [BUILD_DIR, WATCH_TARGET_DIR]
            if grunt.file.exists(f)
                grunt.file.delete(f)

    # Build the dist version, a app.nw zip inside a .app package.
    grunt.registerTask 'build', [
        'prebuild'
        'coffee:compile'
        'copy:forbuild'
        'writepackagejson'
        'nodewebkit'
    ]

    # Build the dist version, then use that package as a compile target for
    # on-change compilation of CoffeeScript source files.
    grunt.registerTask 'dev', [
        'build'
        'preparewatch'
        'copy:forwatch'
        'coffee:watch'
        'watch'
    ]




