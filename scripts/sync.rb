
register 'Sync channel modes'

@@syncs = get_all_data

command 'syncbot', 'Configure syncbot' do
  level! 9 and argc! 3

  src = @connection.canonize @params[0]
  dst = @connection.canonize @params[1]
  modes = @params[2].split ""

  next if src == dst
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
  next if @msg.me?

  network = @connection.name
  channel = @msg.destination_canon
  nick = @msg.nick

  kicked, reason = @msg.parameters.split(/ :/, 2)  

  next unless @@syncs[channel]

  dests = []

  @@syncs[channel].each do |dest, sync|
    next unless sync.include? "k"
    next unless @connection.channels.has_key? dest
    next unless @connection.channels[dest].users.has_key? kicked

    send_kick dest, kicked, "<#{@msg.user}> #{reason}"
    dests << dest
  end
  send_privmsg "#berrypunch", "#{channel} => #{dests.join ", "}: #{@msg.user} kicked #{kicked} \"#{reason}\"" unless dests.empty?
end

event :MODE do
  next unless channel?
  next if @msg.me?

  network = @connection.name
  channel = @msg.destination_canon
  nick = @msg.nick

  params = @msg.raw_arr[3..-1]
  next unless params.length >= 1
  next unless @@syncs[channel]

  modes = parse_mode params[0]
  param = params.length >= 2 ? params[1] : ""

  dests = []

  modes.each do |mode, set|
    next if mode == "k"
    @@syncs[channel].each do |dest, sync|
      next unless sync.include? mode

      send_mode dest, "#{modes[mode] ? '+' : '-'}#{mode} #{param}"
      send_mode channel, "-#{mode} #{param}" if modes[mode] and mode == "b"
      dests << dest
    end
    send_privmsg "#berrypunch", "#{channel} => #{dests.join ", "}: #{@msg.nick} set #{modes[mode] ? '+' : '-'}#{mode} #{param}" unless dests.empty?
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
