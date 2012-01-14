#
# Knife plugin for Cisco UCS
#
# ryan.graham@gmail.com
#


require 'rest_client'
require 'rexml/document'

    module KnifeUCS
      class UcsBladeList < Chef::Knife
 
		banner "knife ucs blade list"
 
        def run
		
			login
		
			list_blades
			
			logout
			
        end
		
		# TODO: Move login\logout to a ucs_base module and include as mixin
		def login
			#puts "Doing aaaLogin"
			
			# For now this IP is my UCSPE instance in VMWARE
			# Move this to command line and/or databags?
			@host = '192.168.145.128'
			user = 'admin'
			pass = 'admin'
			
			# The path for all UCS Manager API stuff is nuova
			# Lets request a session
			response = RestClient.post "http://#{@host}/nuova", 
				"<aaaLogin inName=\"#{user}\" inPassword=\"#{pass}\"></aaaLogin>"
			
			doc = REXML::Document.new(response)
			root = doc.root
			
			# Check for login failure
			if not root.attributes['response'] == 'yes'
				ui.fatal "UCS Login failed. Exiting."
				exit 1
			end
			
			# Grab outCookie for later use
			@cookie = root.attributes['outCookie']
			
			#formatter = REXML::Formatters::Pretty.new
			#formatter.compact = true
			#puts formatter.write(root,"")
			
		end	
		
		def logout
			#puts "Doing aaaLogout"
		
			RestClient.post "http://#{@host}/nuova", 
				"<aaaLogout inCookie=\"#{@cookie}\" />"
				#check for failure? meh. maybe later.
				#but remember the limit is 256 sessions
				#and they can last up to two hours without a refresh or logout.
		end
		
		def list_blades
			
			xml = "<configResolveClass cookie=\"#{@cookie}\" classId=\"computeBlade\"/>"
			response = RestClient.post "http://#{@host}/nuova", xml, :content_type => 'text/xml'

			doc = REXML::Document.new(response)
			
			printf("\n%-21s %-6s %-20s\n","Blade","Power","Profile")
			doc.elements.each("configResolveClass/outConfigs/*") {
				|blade|
				name = blade.attributes["dn"]
				power = blade.attributes["operPower"]
				profile = blade.attributes["assignedToDn"]
				printf("%-19s %-6s %-20s\n",name,power,profile)
			}
		end
 
      end
    end