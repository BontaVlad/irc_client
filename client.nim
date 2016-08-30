let doc = """
Usage:
  client <host> <port> <nickname>
"""

import net, strutils, docopt

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

proc simple_math(input: string) =
  discard

proc random_number(input: string) =
  discard

proc channel_joined(input: string) =
  discard

proc react(socket: Socket, input: string, reactions: varargs[proc]) =
  discard

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
