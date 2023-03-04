package main

import (
	"crypto/ed25519"
	"crypto/x509"
	"encoding/json"
	"flag"
	"fmt"
	"os"

	"github.com/NickCao/xfirm/config"
	"github.com/strongswan/govici/vici"
)

var registryFile = flag.String("registry", "registry.json", "path to registry")
var id4 = flag.String("id4", "", "id for ipv4")
var id6 = flag.String("id6", "", "id for ipv6")

func main() {
	flag.Parse()

	file, err := os.Open(*registryFile)
	if err != nil {
		panic(err)
	}

	decoder := json.NewDecoder(file)
	registry := config.Registy{}
	err = decoder.Decode(&registry)
	if err != nil {
		panic(err)
	}

	sk, _, err := GenerateKeypair()
	if err != nil {
		panic(err)
	}

	pk, err := PubkeyFromPrivateKey(sk)
	if err != nil {
		panic(err)
	}

	sess, err := vici.NewSession()
	if err != nil {
		panic(err)
	}

	key, err := vici.MarshalMessage(EncodePrivateKey(sk))
	if err != nil {
		panic(err)
	}

	_, err = sess.CommandRequest("load-key", key)
	if err != nil {
		panic(err)
	}

	for _, local := range []string{*id4, *id6} {
		for _, remote := range registry {
			conn, err := vici.MarshalMessage(NewConnection(
				[]string{"%any"},
				[]string{remote.Addr, "%any"},
				500,
				500,
				pk,
				pk,
				local,
				remote.Id,
			))
			if err != nil {
				panic(err)
			}

			msg := vici.NewMessage()
			err = msg.Set(fmt.Sprintf("%s-%s", local, remote.Id), conn)
			if err != nil {
				panic(err)
			}

			_, err = sess.CommandRequest("load-conn", msg)
			if err != nil {
				panic(err)
			}
		}
	}

}
