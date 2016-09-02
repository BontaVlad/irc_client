let doc = """
Usage:
  client <host> <port> <nickname>
"""

import
  net,
  strutils,
  sequtils,
  docopt,
  nre,
  options,
  random,
  future

const RPL_ENDOFMOTD = "376"

let args = docopt(doc)
echo args

var nickname = $args["<nickname>"]
var host_name = $args["<host>"]
var port_num = parseInt($args["<port>"])


proc ping_pong(socket: Socket, input: string) =
  if input.startsWith("PING"):
    let output = replace(input, "PING", "PONG")
    echo(output)
    socket.send(output)

proc connect_to_host(socket: Socket) =
  echo "connection to freenode"
  socket.connect(host_name, Port(port_num))

  echo "sending out the credentials"
  socket.send("$#\r\n" % nickname)
  socket.send("NICK $1\r\n USER $1 * 0 :IRC client programmed in Nim!\r\n" % [nickname])

proc join_channels(socket: Socket, channels: varargs[string]) =
  var cmd = "JOIN "

  for ch in items(channels):
    cmd.add(ch & ',')
  cmd.removeSuffix(',')
  socket.send(cmd & "\r\n")
  echo("joining channels: ", cmd)

proc after_motd(socket: Socket, callback: proc, args: varargs[string]) =
  var input = ""
  while true:
    socket.readLine(input)
    if input.len == 0: break
    ping_pong(socket, input)
    echo(input)
    if RPL_ENDOFMOTD in input:
      echo "end of motd"
      callback(socket, args)
      return

proc simple_math(socket: Socket, input: string) =
  let matches = input.match(re":(\w*)!.*PRIVMSG.*:(sum|div|mul|sub) (.*)")
  var res: float = 0.0

  if matches.isNone():
    return
  let nickname = matches.get().captures[0]
  let operation = matches.get().captures[1]
  let numbers_str = matches.get().captures[2].split(re"\s")
  case operation:
    of "sum":
      res = 0
      for num in numbers_str:
        res += parseFloat(num)
    of "sub":
      res = 0
      for num in numbers_str:
        res -= parseFloat(num)
    of "mul":
      res = 1
      for num in numbers_str:
        res *= parseFloat(num)
    of "div":
      for num in numbers_str:
        res /= parseFloat(num)
    else:
      discard

  let cmd = "PRIVMSG $1 $2" % [nickname, $res]
  echo $cmd
  socket.send(cmd & "\r\n")

proc random_number(socket: Socket, input: string) =
  let matches = input.match(re":(\w*)!.*PRIVMSG.*:random")
  if matches.isNone():
    return
  let cmd = "PRIVMSG $1 $2" % [$matches.get().captures[0], $random(1000)]
  echo $cmd
  socket.send(cmd & "\r\n")

proc channel_joined(socket: Socket, input: string) =
  let matches = input.match(re(r":$1!~$2@\d.\d.\d+.\d+ JOIN (#\w*-?\w*)" % [nickname, nickname[..8]]))
  if matches.isNone():
    return
  let cmd = "PRIVMSG $# Hello World!" % $matches.get().captures[0]
  echo $cmd
  socket.send(cmd & "\r\n")

proc react[T: proc](socket: Socket, input: string, reactions: varargs[T]) =
  for react in items(reactions):
    react(socket, input)

proc main() =
  var socket = newSocket()

  connect_to_host(socket)
  after_motd(socket, join_channels, ["#reddit-dailyprogrammer", "#rdp", "#botters-test"])

  var input = ""
  while true:
    socket.readLine(input)
    if input.len == 0: break
    echo(input)
    ping_pong(socket, input)
    react(socket, input, [channel_joined, random_number, simple_math])

  socket.close()

when isMainmodule:
  main()
