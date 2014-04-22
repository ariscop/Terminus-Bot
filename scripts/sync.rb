
register 'Sync channel modes'

@@syncs = get_data :syncs, {}

command 'syncbot', 'Configure syncbot' do
  level! 9 and argc! 3

  src = @connection.canonize @params[0]
  dst = @connection.canonize @params[1]
  modes = @params[2].split ""

  next if src == dst
  @@syncs[src] = {} unless @@syncs[src]

  @@syncs[src][dst] = modes

  store_data :syncs, @@syncs

  reply "#{src} => #{dst} : #{modes.join}"
end

command 'synclist', 'List syncbot syncs' do
  level! 9 and argc! 0

  @@syncs.each do |src, outer|
    outer.each do |dst, modes|
      reply "#{src} => #{dst} : #{modes.join}"
    end
  end
end

command 'syncclear', 'List syncbot syncs' do
  level! 9 and argc! 0

  store_data :syncs, {}
  @@syncs = get_data :syncs
  reply "Cleared"
end

event :KICK do
  next unless channel?
  next if @msg.me?

  kicked, reason = @msg.parameters.split(/ :/, 2)  

  dests = []

  handle_mode @msg.destination_canon, @msg.destination_canon, dests, @msg.nick, "k", true, [kicked, reason]
  send_privmsg "#berrypunch", "#{@msg.destination} => #{dests.join ", "}: #{@msg.nick} kicked #{kicked} \"#{reason}\"" unless dests.empty?
end

event :MODE do
  next unless channel?
  next if @msg.me?

  params = @msg.raw_arr[3..-1]
  parse_mode(params).each do |x|
    dests = []
    mode, set, param = x
    handle_mode @msg.destination_canon, @msg.destination_canon, dests, @msg.nick, mode, set, param
    send_privmsg "#berrypunch", "#{@msg.destination} => #{dests.join ", "}: #{@msg.nick} set #{set ? '+':'-'}#{mode} #{param}" unless dests.empty?
  end
end

helpers do
  def parse_mode params
    modes = []
    plus = true
    index = 1
    params[0].each_char do |mode|
      if mode == "+"
        plus = true
      elsif mode == "-"
        plus = false
      else
        modes << [mode, plus, params[index]]
        index = index + 1
      end
    end
    return modes
  end

  def handle_mode channel, from, dests, user, mode, set, param
    return unless @@syncs[channel]
    @@syncs[channel].each do |dest, sync|
      next unless sync.include? mode
      next unless dest != from

      if dest.chr == "@" then
        dests << dest
        handle_mode dest, from, dests, user, mode, set, param
        next
      end

      if mode == "k" then
        next unless @connection.channels.has_key? dest
        next unless @connection.channels[dest].users.has_key? param[0]

        send_kick dest, param[0], "<#{user}> #{param[1]}"
      else
        send_mode dest, "#{set ? '+':'-'}#{mode} #{param}"
        send_mode channel, "-b #{param}" if set and mode == "b"
      end
      dests << dest
    end
  end
end
