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
	for {
		send(c, "host", "host a", "time", time.Now().Format(time.RFC3339Nano))
		time.Sleep(1 * time.Second)
		// read(c)
		// time.Sleep(1 * time.Second)
	}
}

func conn() radix.Client {
	c, err := radix.NewPool("tcp", "streams:6379", 20)
	if err != nil {
		log.Fatalf("conn: failure to connect %v", err)
	}
	return c
}

func send(c radix.Client, args ...string) {
	args = append([]string{StreamName, "*"}, args...)

	if err := c.Do(radix.Cmd(nil, "XADD", args...)); err != nil {
		log.Printf("doLog: failure to add log %v", err)
		return
	}

	log.Printf("doLog: added log %v", args)
}

func read(c radix.Client) {
	var v interface{}
	if err := c.Do(radix.Cmd(&v, "XREAD", "COUNT", "10", "BLOCK", "2000", "STREAMS", "log", "0")); err != nil {
		log.Printf("read: failure to read log %v", err)
	} else {
		log.Printf("read: fetch logs %s", v)
	}
}
