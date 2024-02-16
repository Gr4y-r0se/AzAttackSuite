['colorize','faraday','json'].each(&method(:require))

if ARGV[0] != '-h' then
	file = File.open(ARGV[0])
	file_data = file.readlines.map(&:chomp)
	file.close

	con = Faraday.new
	puts "The following users exist:\n"

	file_data.each do |i|

		resp = Faraday.post('https://login.microsoftonline.com/common/GetCredentialType') do |req|
			req.headers['Content-Type'] = 'application/json'
			req.body = {Username: "#{i}", isOtherIdpSupported: true}.to_json
		end
		parsed = JSON.parse(resp.body)
		if [0,5,6].include? parsed["IfExistsResult"] then 
			puts "    #{i}".green  
		end
	end
else
	puts 'Pass a list of emails to check. --> ruby AzureVUE.rb [file]'
end
puts "\n\n"
