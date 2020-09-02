package ethereum

import "fmt"

type Client struct {
	Provider string
}

func (client Client) Connect() string {
	fmt.Println("client connected")
	return "connected"
}
