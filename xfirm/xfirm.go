package main

import (
	"crypto/ed25519"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"flag"
	"os"

	"github.com/NickCao/xfirm/config"
	"github.com/strongswan/govici/vici"
)

var configFile = flag.String("config", "/etc/xfirm.conf", "path to config file")

func main() {
	flag.Parse()

	sess, err := vici.NewSession()
	if err != nil {
		panic(err)
	}

	file, err := os.Open(*configFile)
	if err != nil {
		panic(err)
	}
	decoder := json.NewDecoder(file)

	cfg := config.Config{}
	err = decoder.Decode(&cfg)
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
			conn, err := vici.MarshalMessage(Connection{
				Version:     2,
				Encap:       true,
				LocalAddrs:  local.LocalAddrs,
				RemoteAddrs: remote.RemoteAddrs,
				RemotePort:  int(remote.RemotePort),
				IfIdIn:      "%unique",
				IfIdOut:     "%unique",
				Local: Local{
					Auth: "pubkey",
					Pubkeys: []string{string(pem.EncodeToMemory(&pem.Block{
						Type:  "PUBLIC KEY",
						Bytes: publicKey,
					}))},
				},
				Remote: Remote{
					Auth: "pubkey",
					Pubkeys: []string{string(pem.EncodeToMemory(&pem.Block{
						Type:  "PUBLIC KEY",
						Bytes: remote.PublicKey,
					}))},
				},
				Children: map[string]Child{
					"default": {
						LocalTS:     []string{"0.0.0.0/0", "::/0"},
						RemoteTs:    []string{"0.0.0.0/0", "::/0"},
						StartAction: "trap|start",
					},
				},
			})
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
