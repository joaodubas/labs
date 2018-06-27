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
		mID = recv(c, mID)
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
	if err != nil && !strings.Contains(err.Error(), "name already exists") {
		log.Fatalf("group: failure to create stream group %s", err.Error())
	}
	log.Printf("group: created successfully %v", r)
}

func recv(c redis.Conn, sID string) string {
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
	if err != nil {
		log.Printf("recv: failed to read for group %v", err)
	} else {
		// TODO (jpd): convert this in a method to parse redis stream message.
		// A message is represented by a slice of streams, containing a slice
		// of messages. Each message is a slice with a message id and a slice
		// of key values. Example: `[[stream [[id [[k] [v]]]]]]`
		for _, m := range r {
			for i, n := range m.([]interface{}) {
				if i == 0 {
					log.Printf(
						"recv: received stream (%d) %v",
						len(n.([]uint8)),
						string(n.([]uint8)),
					)
				} else {
					for _, o := range n.([]interface{}) {
						// NOTE (jpd): from here on we have a message.
						for j, p := range o.([]interface{}) {
							if j == 0 {
								sID = p.(string)
								log.Printf(
									"recv: received key (%d) %s",
									len(p.(string)),
									p.(string),
								)
							} else {
								for _, q := range p.([]interface{}) {
									log.Printf(
										"recv: received message (%d) %s",
										len(q.([]uint8)),
										string(q.([]uint8)),
									)
								}
							}
						}
						// NOTE (jpd): after process a message, ack it.
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
		log.Printf("ack: failed to ack message %s", messageID)
	} else {
		log.Printf("ack: success to ack message %s (%v)", messageID, r)
	}
}
