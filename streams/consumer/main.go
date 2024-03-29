package main

import (
	"fmt"
	"log"
	"strings"
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
	group(c)
	mID := ">"
	for {
		// mID = recv(c, mID)
		recv(c, mID)
		time.Sleep(1 * time.Second)
	}
}

// conn stablish a connection with redis and return it.
func conn() redis.Conn {
	c, err := redis.Dial("tcp", "streams:6379")
	if err != nil {
		log.Fatalf("conn: failure to connect with redis instance %v", err)
	}
	return c
}

// group create a consumer group for a given stream.
func group(c redis.Conn) {
	r, err := c.Do("XGROUP", "CREATE", StreamName, GroupName, "0")
	if err != nil && !strings.Contains(err.Error(), "name already exists") {
		log.Fatalf("group: failure to create stream group %s", err.Error())
	}
	log.Printf("group: created successfully %v", r)
}

// recv will block waiting to receive a given number of messages in a stream.
func recv(c redis.Conn, sID string) string {
	args := []interface{}{
		"GROUP",
		GroupName,
		ConsumerName,
		"COUNT",
		10,
		"BLOCK",
		500,
		"STREAMS",
		StreamName,
		sID,
	}
	r, err := redis.Values(c.Do("XREADGROUP", args...))
	if err != nil {
		log.Printf("recv: failed to read for group %v", err)
	} else {
		// TODO: (jpd) convert this in a method to parse redis stream message.
		// A message is represented by a slice of streams, containing a slice
		// of messages. Each message is a slice with a message id and a slice
		// of key values. Example: `[[stream [[id [[k] [v]]]]]]`
		for _, m := range r {
			for i, n := range m.([]interface{}) {
				if i == 0 {
					// NOTE: (jpd) name of stream
					if k, err := redis.String(n, nil); err != nil {
						log.Printf(
							"recv: failed to convert key (%v):\n%v",
							n,
							err,
						)
					} else {
						log.Printf(
							"recv: received stream (%d) %s",
							len(k),
							k,
						)
					}
				} else {
					for _, o := range n.([]interface{}) {
						// NOTE: (jpd) from here on we have a message.
						for j, p := range o.([]interface{}) {
							if j == 0 {
								// NOTE: (jpd) message id
								sID = string(p.([]uint8))
								log.Printf(
									"recv: received key (%d) %s",
									len(p.([]uint8)),
									sID,
								)
							} else {
								// NOTE: (jpd) message content
								if sm, err := redis.StringMap(p, nil); err != nil {
									log.Printf("recv: failed to convert message (%v):i\n%v", p, err)
								} else {
									log.Printf("recv: received message %v", sm)
								}
							}
						}
						// NOTE: (jpd) after process a message, ack it.
						ack(c, sID)
					}
				}
			}
		}
	}
	return sID
}

func ack(c redis.Conn, messageID string) {
	if r, err := c.Do("XACK", StreamName, GroupName, messageID); err != nil {
		log.Printf("ack: failed to ack message %s (%v)", messageID, err)
	} else {
		log.Printf("ack: success to ack message %s (%v)", messageID, r)
	}
}
