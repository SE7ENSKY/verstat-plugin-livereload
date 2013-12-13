module.exports = (next) ->
	@on "serve", (app, server) =>
		if @env is 'dev'
			livereload = require 'livereload'
			livereload.createServer
				exts: ['html', 'js', 'css', 'png', 'jpg', 'gif']
				applyCSSLive: on
				applyJSLive: off
			.watch @config.out
			@log "INFO", "livereload started"

	next()
