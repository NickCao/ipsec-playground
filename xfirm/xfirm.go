package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"

	"github.com/NickCao/xfirm/config"
	"github.com/strongswan/govici/vici"
)

// openssl genpkey -algorithm ed25519 -outform PEM
// openssl pkey -pubout

const PRIVATE_KEY = `
-----BEGIN PRIVATE KEY-----
MC4CAQAwBQYDK2VwBCIEII2FUjQSzGXYmw5taavsEePCHUsQ3VyxfdgniC9Ndvvz
-----END PRIVATE KEY-----
`

const PUBLIC_KEY = `
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEAmW582ua12TEQq7sFw1h5lBNqU7UTVhA75LLTNfOPR0k=
-----END PUBLIC KEY-----
`

var registryPath = flag.String("registry", "registry.json", "path to registry")
var configPath = flag.String("config", "config.json", "path to config")

func main() {
	flag.Parse()

	// load registry
	registryFile, err := os.Open(*registryPath)
	if err != nil {
		panic(err)
	}

	registryDecoder := json.NewDecoder(registryFile)

	registry := config.Registy{}

	err = registryDecoder.Decode(&registry)
	if err != nil {
		panic(err)
	}

	// load config
	configFile, err := os.Open(*configPath)
	if err != nil {
		panic(err)
	}

	configDecoder := json.NewDecoder(configFile)

	config := config.Config{}

	err = configDecoder.Decode(&config)
	if err != nil {
		panic(err)
	}

	session, err := vici.NewSession()
	if err != nil {
		panic(err)
	}

	key, err := vici.MarshalMessage(PrivateKey{
		Type: "any",
		Data: PRIVATE_KEY,
	})
	if err != nil {
		panic(err)
	}

	_, err = session.CommandRequest("load-key", key)
	if err != nil {
		panic(err)
	}

	for _, local := range config.Endpoints {
		for _, identity := range registry {
			for _, remote := range identity.Endpoints {
				n := NewConnection(
					local,
					remote,
					PUBLIC_KEY,
					PUBLIC_KEY,
				)
				if n == nil {
					continue
				}

				fmt.Printf("local: %+v, remote: %+v\n", local, remote)

				conn, err := vici.MarshalMessage(*n)
				if err != nil {
					panic(err)
				}

				msg := vici.NewMessage()
				err = msg.Set(fmt.Sprintf("%s-%s", local.Id, remote.Id), conn)
				if err != nil {
					panic(err)
				}

				_, err = session.CommandRequest("load-conn", msg)
				if err != nil {
					panic(err)
				}
			}
		}
	}

}
