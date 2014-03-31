
register 'Sync channel modes'

@@syncs = get_all_data

command 'syncbot', 'Configure syncbot' do
  level! 9 and argc! 3

  src = @connection.canonize @params[0]
  dst = @connection.canonize @params[1]
  modes = @params[2].split ""

  @@syncs[src] = {} unless @@syncs[src]

  @@syncs[src][dst] = modes

  store_data src, @@syncs[src]

  reply "#{src} => #{dst} : #{modes}"
end

command 'synclist', 'List syncbot syncs' do
  level! 9 and argc! 0

  @@syncs.each do |src, outer|
    outer.each do |dst, modes|
      reply "#{src} => #{dst} : #{modes}"
    end
  end
end

command 'syncclear', 'List syncbot syncs' do
  level! 9 and argc! 0

  init_data
  @@syncs = get_all_data
  reply "Cleared"
end

event :KICK do
  next unless channel?

  network = @connection.name
  channel = @msg.destination_canon
  nick = @msg.nick

  kicked, reason = @msg.parameters.split(/ :/, 2)  

  next unless @@syncs[channel]

  @@syncs[channel].each do |dest, sync|
    if sync.include? "b" then
      send_kick dest, kicked, "<#{@msg.user}> #{reason}"
      send_privmsg "#berrypunch", "#{channel} => #{dest}: #{@msg.user} kicked #{kicked} \"#{reason}\""
    end
  end
end

event :MODE do
  next unless channel?

  network = @connection.name
  channel = @msg.destination_canon
  nick = @msg.nick

  params = @msg.raw_arr[3..-1]
  next unless params.length > 1
  next unless @@syncs[channel]

  modes = parse_mode params[0]

  @@syncs[channel].each do |dest, sync|
    if sync.include?("b") and modes.include?("b")
      send_mode dest, "#{modes['b'] ? '+' : '-'}b #{params[1]}"
      send_privmsg "#berrypunch", "#{channel} => #{dest}: #{@msg.nick} set #{modes['b'] ? '+' : '-'}b #{params[1]}"
      send_mode channel, "-b #{params[1]}" if modes['b']
    end
  end
end

helpers do
  def parse_mode mode
    keys = {}
    plus = true
    key = false
    mode.each_char do |key|
      if key == "+"
        plus = true
      elsif key == "-"
        plus = false
      else
        keys[key] = plus
      end
    end
    return keys
  end
end
