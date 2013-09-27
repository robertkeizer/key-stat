log	= require( "logging" ).from __filename
http	= require "http"
async	= require "async"

# Define the view url.
view_url = "http://localhost:5984/key-stat/_design/test/_view/meh"

# 2 hours worth of 5 minute images.
num_images	= 24
heatmap_length	= 5 * 60 * 1000

now = new Date( ).getTime( )

async.map [1..num_images], ( i, cb ) ->
	# Determine the starttime and the endtime.
	end_time	= now - (i*heatmap_length)
	start_time	= end_time - heatmap_length

	# Rather than setting up a totally new object, just use strings.
	# I'm lazy :)

	tmp_url = view_url + "?startkey=#{start_time}&endkey=#{end_time}"
	req = http.get tmp_url, ( res ) ->
		res.setEncoding "utf8"
		_r = ""
		res.on "data", ( chunk ) ->
			_r += chunk
		res.on "end", ( ) ->
			_p = { }
			for row in JSON.parse( _r ).rows
				if not _p[row.value]?
					_p[row.value] = 0
				_p[row.value] += 1
			
			cb null, _p

	req.on "error", cb
, ( err, res ) ->
	if err
		log "Error: #{err}"
		process.exit 1

	log res
