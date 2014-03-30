#

register 'Autokick spamers'

@@nicks = Hash.new

event :PRIVMSG  do
  now = Time.now.to_f
    
  #ignore non channel messages
  next if @msg.query?
  
  next if op? or half_op? or voice? 
  
  cut, time = get_data @msg.destination_canon, [0, 0]
  next if time < 1 or cut < 2
  
  key = @msg.nick_canon
  data = (@@nicks[key] or Array.new)
  
  data.pop unless data.length < cut
  
  data.insert(0, now)
  
  if data.length == cut and now - data.last <= time then
    kickmsg = "You were kicked for sending #{cut} messages in #{time} seconds."
    
    send_privmsg("ChanServ", "kick #{@msg.destination} #{@msg.nick} " + kickmsg)
    
    send_privmsg("#berrypunch", "Kicked #{@msg.nick} from #{@msg.destination}")
  end
  
  @@nicks[key] = data
  
end


command 'kickbot', 'Configure spamkick' do
  next unless op?
  argc! 2
  
  #begin
    cut = Integer(@params[0])
    time = Integer(@params[1])
  
    store_data(@msg.destination_canon, [cut, time])
    reply("Setting kickbot to " + cut.to_s + " messages in " + time.to_s + " seconds")
  #rescue
    #case params[0]
      #when "chankick"
      #  chankick = (params[1] == "true" || params[1] == "on") ? true : false
      #  store_data(@msg.destination, chankick)
      #  msg.reply("Kick via chanserv is " + (chankick ? "On" : "Off"))
      #when "monitor"
      #  monitor = params[1] == "off" ? "" : params[1]
      #  store_data("#{@msg.destination},monitor", monitor)
      #  msg.reply("Monitor channel is " + (monitor.empty? ? "Off" : "On"))
      #else
        #reply("Not a valid command, silly")
     #end
  #end
end
