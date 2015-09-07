#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2014 Rylee Fowler <rylee@rylee.me>
#                    Justin Kaufman <akaritakai@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

# TODO:
#   - Configurable max dice.
#   - MORE TOKENS (consult the roll20 dice reference if in need of ideas)

# TODO: Add ability to T-b to define constants for your scripts.

register 'Provides a high-flexibility dice simulator.'

command 'dice', 'Roll dice.' do
  argc! 1

  dice_strs = @params.first.scan /\S+/

  if dice_strs.size > 5
    raise 'You may not request more than 5 dice simulations at a time.'
  end

  # TODO: Streamline rolling dice and outputting for clarity

  results = []

  i = 1
  dice_strs.each do |dice_str|
    rolls = roll_dice dice_str
    sum = 0
    rolls.each { |roll| sum += roll }
    results << "Dice set #{i}: result: #{sum} dice: [#{rolls.join(', ')}]"
    i = i + 1
  end

  reply results.join(' ')
end

helpers do
  def roll_dice dice_str
    operators = Regexp.escape '+-*'

    raise 'Simulation format must be [count]d<sides>[k<keep>][+/-/*<modifier>]' if dice_str.match(/^(\d+)?d\d+(k\d+)?([#{operators}]\d+)*$/).nil?

    settings = Hash.new()
    type_map = {
      :count => /^(\d+)/,                 # Number of dice to roll
      :sides => /d(\d+)/,                 # Number of sides on the dice
      :keep => /k(\d+)/,                  # Number of dice to keep
      :mod => /((?:[#{operators}]\d+)*)$/ # Expression to add to every roll
    }

    # Get settings from dice string
    type_map.each do |setting, regex|
      parsed = dice_str.scan(regex).first.first.to_s rescue nil
      settings[setting] = (parsed.match(/^\d+$/).nil?) ? parsed : Integer(parsed) rescue nil
    end

    # Sanity checks
    settings[:count] = 1 if settings[:count].nil?
    raise 'You may only roll up to 100 dice.' if settings[:count] > 100
    raise 'You must roll a positive number of dice.' if settings[:count] <= 0

    raise 'You must specify a number of sides.' if settings[:sides].nil?
    raise 'You may only roll dice of up to 100 sides.' if settings[:sides] > 100
    raise 'You must only roll dice with a positive number of sides.' if settings[:sides] <= 0

    if !settings[:keep].nil?
      raise 'You must choose to keep a positive number of dice if specified.' if settings[:keep] <= 0
      raise 'You must not choose to keep more dice than you have chosen to roll.' if settings[:keep] > settings[:count]
    end

    rolls = []

    # Make the rolls
    settings[:count].times { rolls << rand(settings[:sides]) + 1 }

    # Remove lowest dice according to keep
    settings[:keep] = Integer(settings[:keep]) rescue 0
    settings[:keep] = rolls.size - settings[:keep] unless settings[:keep] == 0
    settings[:keep].times { rolls.delete_at rolls.index rolls.min }

    # Add the modifier
    rolls.collect! do |roll|
      unless settings[:mod].nil?
        mod = settings[:mod].match(/[\d#{operators}]*/)
        eval(roll.to_s + mod.to_s).to_i
      end
    end

    rolls
  end
end
