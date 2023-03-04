package main

import (
	"crypto/ed25519"
	"crypto/x509"
	"encoding/json"
	"flag"
	"github.com/strongswan/govici/vici"
	"os"
)

var configFile = flag.String("config", "/etc/xfirm.conf", "path to config file")

func main() {
	flag.Parse()

	file, err := os.Open(*configFile)
	if err != nil {
		panic(err)
	}
	decoder := json.NewDecoder(file)

	cfg := config.Config{}
	err = decoder.Decode(&cfg)

	sk, _, err := GenerateKeypair()
	if err != nil {
		panic(err)
	}

	pk, err := PubkeyFromPrivateKey(sk)
	if err != nil {
		panic(err)
	}

	for _, local := range cfg.Locals {
		key, err := vici.MarshalMessage(PrivateKey{
			Type: "any",
			Data: string(pem.EncodeToMemory(&pem.Block{
				Type:  "PRIVATE KEY",
				Bytes: local.PrivateKey,
			})),
		})
		_, err = sess.CommandRequest("load-key", key)
		if err != nil {
			panic(err)
		}
		privateKey, err := x509.ParsePKCS8PrivateKey(local.PrivateKey)
		if err != nil {
			panic(err)
		}
		publicKey, err := x509.MarshalPKIXPublicKey(privateKey.(ed25519.PrivateKey).Public())
		if err != nil {
			panic(err)
		}
		for _, remote := range cfg.Remotes {
			conn, err := vici.MarshalMessage(NewConnection(
				[]string{"192.168.1.1", "%any"},
				[]string{"192.168.1.2", "%any"},
				500,
				500,
				publicKey,
				publicKey,
				"some_unique_id",
				"some_unique_id",
			))
			if err != nil {
				panic(err)
			}
			msg := vici.NewMessage()
			err = msg.Set("some random but unique name", conn)
			if err != nil {
				panic(err)
			}
			if _, err = sess.CommandRequest("load-conn", msg); err != nil {
				panic(err)
			}
		}
	}

}
