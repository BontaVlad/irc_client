let doc = """
Usage:
  client <host> <port> <nickname>
"""

import
  net,
  strutils,
  docopt,
  nre,
  options

# macro curry(f: typed; args: varargs[untyped]): untyped =
#   let ty = getType(f)
#   assert($ty[0] == "proc", "first param is not a function")
#   let n_remaining = ty.len - 2 - args.len
#   assert n_remaining > 0, "cannot curry all the parameters"
#   #echo treerepr ty

# var callExpr = newCall(f)
# args.copyChildrenTo callExpr

# var params: seq[NimNode] = @[]
# # return type
# params.add ty[1]

# for i in 0 .. <n_remaining:
#   let param = ident("arg"& $i)
#   params.add newIdentDefs(param, ty[i+2+args.len])
#   callExpr.add param
#   result = newProc(procType = nnkLambda, params = params, body = callExpr)

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

proc simple_math(input: string): string =
  return input

proc random_number(input: string): string =
  return input

proc channel_joined(input: string): string =
  let matches = input.match(re":Vlad0397-bot!~Vlad0397-@\d.\d.\d+.\d+ JOIN (#\w+)")
  echo($matches.get())
  # if matches:
  #   echo "found something"
  # echo "found nothing"
  # if len(matches) > 0:
  #   echo matches[0]
  #   return "PRIVMSG $# :Hello World!" % matches[0]
  # echo "no matches"

proc react[T: proc](socket: Socket, input: string, reactions: varargs[T]) =
  echo("reacting")
  var cons: seq[string] = @[]
  for react in items(reactions):
    cons.add(react(input))
  # echo(cons)

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
