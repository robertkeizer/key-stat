log	= require( "logging" ).from __filename
async	= require "async"
fs	= require "fs"
url	= require "url"
http	= require "http"

couchdb_url = "http://localhost:5984/key-stat/"

# Simple mapping of values to particular keys.
map = {"2":"1","3":"2","4":"3","5":"4","6":"5","7":"6","8":"7","9":"8","10":"9","12":"-","13":"=","15":"_tab_","16":"q","17":"w","18":"e","19":"r","20":"t","21":"y","22":"u","23":"i","24":"o","25":"p","28": "_enter_","29":"_ctrl_","30":"a","31":"s","32":"d","33":"f","34":"g","35":"h","36":"j","37":"k","38":"l","41":"`","43": "|", "44":"z","45":"x","46":"c","47":"v","48":"b","49":"n","50":"m","51":",","52":".","54":"_shift_","56":"_alt_"}

# 30 seconds.
timeout	= ( 30 * 1000 )

# Running object.
running = { }

_loop = ( ) ->
	setTimeout ( ) ->
		send ( ) ->
			_loop( )
		return

	, timeout

_loop( )

send = ( cb ) ->
	# Clear out running.
	to_send = running
	running = { }

	_options = url.parse couchdb_url
	delete _options['search']
	_options['method']	= "POST"
	_options['headers']	= { "content-type": "application/json" }

	log "Sending data.."
	req = http.request _options, ( res ) ->
		res.setEncoding "utf8"
		_r = ""
		res.on "data", ( chunk ) ->
			_r += chunk

		res.on "end", ( ) ->
			log "Done sending data."
			return cb( )
		
	# If we aren't able to log the event, error out.
	req.on "error", ( err ) ->
		return cb err

	# Send our data
	req.write JSON.stringify { "date": new Date( ).getTime( ), "timespan": timeout, "keys": to_send }
	req.end( )

fs.open "/dev/input/event3", "r", ( err, fd ) ->
	if err
		log "Unable to open the keyboard."
		process.exit 1

	async.forever ( cb ) ->
		buff = new Buffer 48
		fs.read fd, buff, 0, 48, null, ( err, bytes_read, buff ) ->
			if err
				return cb err

			_type	= buff.readUInt16LE 16
			_code	= buff.readUInt16LE 18
			_val	= buff.readInt32LE 20

			# We only care about the keys that are defined
			# in map.
			if not map[_val]?
				return cb( )
		
			if not running[map[_val]]?
				running[map[_val]] = 0

			running[map[_val]] += 1

			cb null
	, ( err ) ->
		log "Fatal error: #{err}"
		process.exit 1
