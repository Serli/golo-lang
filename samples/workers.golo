module Workers

import java.lang.Thread
import java.util.concurrent
import gololang.concurrent.workers.WorkerEnvironment

local function pusher = |queue, message| -> queue: offer(message)

local function generator = |port, message| {
  foreach (i in range(0, 100)) {
    port: send(message)
  }
}

function main = |args| {

  let env = WorkerEnvironment.builder(): withFixedThreadPool()
  let queue = ConcurrentLinkedQueue()

  let pusherPort = env: spawn(^pusher: bindTo(queue))
  let generatorPort = env: spawn(^generator: bindTo(pusherPort))

  let finishPort = env: spawn(|any| -> env: shutdown())

  foreach (i in range(0, 10)) {
    generatorPort: send("[" + i + "]")
  }
  Thread.sleep(2000_L)
  finishPort: send("Die!")

  env: awaitTermination(2000)
  println(queue: reduce("", |acc, next| -> acc + " " + next))
}

