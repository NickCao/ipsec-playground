package main

import (
	"encoding/pem"
)

func EncodePrivkey(key []byte) PrivateKey {
	return PrivateKey{
		Type: "any",
		Data: string(pem.EncodeToMemory(&pem.Block{
			Type:  "PRIVATE KEY",
			Bytes: key,
		})),
	}
}

func EncodePubkey(key []byte) string {
	return string(pem.EncodeToMemory(&pem.Block{
		Type:  "PUBLIC KEY",
		Bytes: key,
	}))
}

func NewConnection(
	localAddrs []string,
	remoteAddrs []string,
	localPort int,
	remotePort int,
	localPubkey []byte,
	remotePubkey []byte,
	localId string,
	remoteId string,
) Connection {
	return Connection{
		Version:     2,
		LocalAddrs:  localAddrs,
		RemoteAddrs: remoteAddrs,
		LocalPort:   localPort,
		RemotePort:  remotePort,
		Encap:       true,
		KeyingTries: 0,
		Unique:      "replace",
		IfIdIn:      "%unique",
		IfIdOut:     "%unique",
		Local: Local{
			Auth:    "pubkey",
			Id:      localId,
			Pubkeys: []string{EncodePubkey(localPubkey)},
		},
		Remote: Remote{
			Auth:    "pubkey",
			Id:      remoteId,
			Pubkeys: []string{EncodePubkey(remotePubkey)},
		},
		Children: map[string]Child{
			"default": {
				LocalTS:     []string{"0.0.0.0/0", "::/0"},
				RemoteTs:    []string{"0.0.0.0/0", "::/0"},
				Mode:        "tunnel",
				StartAction: "trap|start",
			},
		},
	}
}

type Connection struct {
	Version     int              `vici:"version"`
	LocalAddrs  []string         `vici:"local_addrs"`
	RemoteAddrs []string         `vici:"remote_addrs"`
	LocalPort   int              `vici:"local_port"`
	RemotePort  int              `vici:"remote_port"`
	Encap       bool             `vici:"encap"`
	KeyingTries int              `vici:"keyingtries"`
	Unique      string           `vici:"unique"`
	IfIdIn      string           `vici:"if_id_in"`
	IfIdOut     string           `vici:"if_id_out"`
	Local       Local            `vici:"local"`
	Remote      Remote           `vici:"remote"`
	Children    map[string]Child `vici:"children"`
}

type Local struct {
	Auth    string   `vici:"auth"`
	Id      string   `vici:"id"`
	Pubkeys []string `vici:"pubkeys"`
}

type Remote struct {
	Auth    string   `vici:"auth"`
	Id      string   `vici:"id"`
	Pubkeys []string `vici:"pubkeys"`
}

type Child struct {
	LocalTS     []string `vici:"local_ts"`
	RemoteTs    []string `vici:"remote_ts"`
	Mode        string   `vici:"mode"`
	StartAction string   `vici:"start_action"`
}

type PrivateKey struct {
	Type string `vici:"type"`
	Data string `vici:"data"`
}
