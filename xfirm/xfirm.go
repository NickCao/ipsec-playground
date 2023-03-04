package main

import (
	"encoding/base64"
	"encoding/json"
	"flag"
	"fmt"
	"os"

	"github.com/NickCao/xfirm/config"
	"github.com/strongswan/govici/vici"
)

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

	// using static key pair to ease testing
	sk, err := base64.RawStdEncoding.DecodeString("MC4CAQAwBQYDK2VwBCIEIKA57upEiuTmii9iE8d79U5896A7uV9kC78f6fJwQMbx")
	if err != nil {
		panic(err)
	}

	pk, err := PubkeyFromPrivateKey(sk)
	if err != nil {
		panic(err)
	}

	key, err := vici.MarshalMessage(EncodePrivateKeyMessage(sk))
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
				conn, err := vici.MarshalMessage(NewConnection(
					local,
					remote,
					pk,
					pk,
				))
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
