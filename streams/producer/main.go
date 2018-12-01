package main

import (
	"fmt"
	"log"
	"time"

	"github.com/mediocregopher/radix.v3"
)

// StreamName represents the series name used to store stream in redis.
const StreamName = "log"

func main() {
	fmt.Println("will do something amazing")
	c := conn()
	// TODO (jpd): this loop should be inside a goroutine.
	for {
		send(c, "host", "host a", "time", time.Now().Format(time.RFC3339Nano))
		time.Sleep(62 * time.Millisecond)
	}
}

func conn() radix.Client {
	c, err := radix.NewPool("tcp", "streams:6379", 20)
	if err != nil {
		log.Fatalf("conn: failure to connect %v", err)
	}
	return c
}

// send a message for the specified stream.
//
// `message` is defined as key, value pairs in a sequence of arguments.
func send(c radix.Client, args ...string) {
	// TODO (jpd): change send to be a goroutine.
	args = append([]string{StreamName, "*"}, args...)

	if err := c.Do(radix.Cmd(nil, "XADD", args...)); err != nil {
		log.Printf("send: failure to add log %v", err)
		return
	}

	log.Printf("send: added log %v", args)
}

// read messages from specified stream.
func read(c radix.Client) {
	// TODO (jpd): change read to be a goroutine.
	var v interface{}
	if err := c.Do(radix.Cmd(&v, "XREAD", "COUNT", "10", "BLOCK", "2000", "STREAMS", "log", "0")); err != nil {
		log.Printf("read: failure to read log %v", err)
	} else {
		log.Printf("read: fetch logs %s", v)
	}
}
