require 'twitter'
require 'chunky_png'

# select a 24-bit RGB color using a 24-bit LFSR (tap layout due to:
# http://www.xilinx.com/support/documentation/application_notes/xapp052.pdf)
def choose_color(last)
	tap24 = (last & 0x800000) != 0 # 1000_0000_0000_0000_0000_0000
	tap23 = (last & 0x400000) != 0 # 0100_0000_0000_0000_0000_0000
	tap22 = (last & 0x200000) != 0 # 0010_0000_0000_0000_0000_0000
	tap17 = (last & 0x010000) != 0 # 0000_0001_0000_0000_0000_0000
	xnor = !(tap24 ^ tap23 ^ tap22 ^ tap17)
	
	if xnor
		return ((last << 1) & 0xffffff) | 0x00000001
	else
		return ((last << 1) & 0xffffff)
	end
end

FIRST = 0x00000000

def chunkify_color(color)
	nameformat_color = (color << 8)
	named_color = ChunkyPNG::Color::PREDEFINED_COLORS.find do |k, v| 
		v == nameformat_color
	end

	drawformat_color = (color << 8) | 0xff

	return drawformat_color, (named_color[0] if named_color)
end

def make_color_png(color)
	rgba, w3cname = chunkify_color(color)
	hex = color.to_s(16)
	png = ChunkyPNG::Image.new(400, 300, rgba)
	filename = "#{hex}_#{w3cname}.png"

	png.save(filename)

	return hex, w3cname, filename
end


def test_lfsr
	chosen = []
	last = FIRST
	n = 1

	until (n == 2 ** 24) do
		last = choose_color(last)
		puts "#{n}: #{last}" if (n % 1000 == 0)

		fail "duplicate color #{last} after #{n}" if chosen[last]
		fail "high-order bits set" if (last & 0xff000000) != 0

		chosen[last] = true
		n += 1
	end

	puts "test passed"
end

def test_pngs(start_color, n)
	next_color = start_color

	n.times do
		puts make_color_png(next_color)
		next_color = choose_color(next_color)
	end
end

# remove before flight
Twitter.configure do |config|
	config.consumer_key = ENV["CONSUMER_KEY"]
	config.consumer_secret = ENV["CONSUMER_SECRET"]
	config.oauth_token = ENV["OAUTH_TOKEN"]
	config.oauth_token_secret = ENV["OAUTH_TOKEN_SECRET"]
	config.connection_options = 
		Twitter::Default::CONNECTION_OPTIONS.merge(:request => {
				:open_timeout => 10,
				:timeout => 20
			})
end

def tweet
	last_color = /0x[0-9a-f]{6}/.match(Twitter.user.status.text)[0].to_i(16) # gross	
	this_color = choose_color(last_color)
	hex, w3cname, filename = make_color_png(this_color)

	if w3cname then
		tweet_text = "0x#{hex} (##{w3cname})"
	else
		tweet_text = "0x#{hex}"
	end

	File.open(filename) do |f|
		Twitter.update_with_media(tweet_text, f)
	end

	File.delete(filename)
end