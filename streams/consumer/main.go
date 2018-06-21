package main

import (
	"fmt"
	"log"
	"time"

	"github.com/gomodule/redigo/redis"
)

const (
	// StreamName represent series name for a redis stream
	StreamName = "log"
	// GroupName represents consumer group name for a redis stream
	GroupName = "Group"
	// ConsumerName represents specific consumer inside a consumer group
	ConsumerName = "Consumer"
)

func main() {
	fmt.Println("consumer")
	c := conn()
	// group(c)
	for {
		recv(c, "0-0")
		time.Sleep(2 * time.Second)
	}
}

func conn() redis.Conn {
	c, err := redis.Dial("tcp", "streams:6379")
	if err != nil {
		log.Fatalf("conn: failure to connect with redis instance %v", err)
	}
	return c
}

func group(c redis.Conn) {
	r, err := c.Do("XGROUP", "CREATE", StreamName, GroupName, "0")
	if err != nil {
		log.Fatalf("group: failure to create stream group %v", err)
	}
	log.Printf("group: created successfully %v", r)
}

func recv(c redis.Conn, sID string) {
	args := []interface{}{
		"GROUP",
		GroupName,
		ConsumerName,
		"COUNT",
		10,
		"BLOCK",
		2000,
		"STREAMS",
		StreamName,
		sID,
	}
	r, err := redis.Values(c.Do("XREADGROUP", args...))
	// rp, err := redis.Values(r, err)
	// m, err := redis.Strings(rp, err)
	if err != nil {
		log.Printf("recv: failed to read for group %v", err)
	} else {
		log.Printf("recv: received reply (%d) %v", len(r), r)
	}
}
