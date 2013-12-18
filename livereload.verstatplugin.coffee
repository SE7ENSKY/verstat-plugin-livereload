request = require 'request'
tinylr = require 'tiny-lr'

module.exports = (next) ->
	return next() if @env isnt 'dev'

	port = 35729
	debounceTimeout = 500
	opts = {}

	@postprocessor 'livereload-injector',
		extname: '.html'
		priority: 9999
		postprocess: (file, donePostprocessor) =>
			inject = (s) ->
				s.replace "</body>", """
					<script>document.write('<script src="http://' + (location.host || 'localhost').split(':')[0] + ':#{port}/livereload.js?snipver=1"></' + 'script>')</script>
					</body>
				"""
			if file.process and file.processor isnt null
				file.processed = inject file.processed
				@modified file
			else
				file.source = inject file.source
				@modified file
			donePostprocessor()

	changedFiles = []
	changedTimeout = null
	changedFile = (filePath) =>
		clearTimeout changedTimeout if changedTimeout
		changedFiles.push filePath if filePath not in changedFiles
		changedTimeout = setTimeout =>
			if changedFiles.length > 0
				@log "INFO", "livereload files", changedFiles
				# curl -X POST http://localhost:35729/changed -d '{ "files": ["style.css", "app.js"] }'
				request
					url: "http://localhost:#{port}/changed"
					method: "POST"
					json: yes
					body: files: changedFiles
				, (err, res, body) =>
					if err then @log "ERROR", "livereload tinylr error", err
				changedFiles = []
				clearTimeout changedTimeout
		, debounceTimeout

	@on "serve", (app, server) =>
		tinylr(opts).listen port, (err) =>
			if err then @log "ERROR", "livereload server failed", err
			else
				@log "INFO", "livereload server started"

		@on "copyFile", (file) => changedFile file.filename
		@on "writeFile", (file) => changedFile file.filename
		@on "removeFile", (file) => changedFile file.filename

	next()
