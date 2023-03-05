package main

import (
	"github.com/NickCao/xfirm/config"
)

func NewConnection(
	localEndpoint config.Endpoint,
	remoteEndpoint config.Endpoint,
	localPublicKey string,
	remotePublicKey string,
) *Connection {
	if localEndpoint.Id == remoteEndpoint.Id {
		return nil
	}

	if localEndpoint.Family != remoteEndpoint.Family {
		return nil
	}

	var remoteAddress []string

	if remoteEndpoint.Address != "" {
		remoteAddress = append(remoteAddress, remoteEndpoint.Address)
	}

	var localAddress string

	switch localEndpoint.Family {
	case "ip4":
		localAddress = "0.0.0.0/0"
		remoteAddress = append(remoteAddress, "0.0.0.0/0")
	case "ip6":
		localAddress = "::/0"
		remoteAddress = append(remoteAddress, "::/0")
	default:
		return nil
	}

	if localEndpoint.Address != "" {
		localAddress = localEndpoint.Address
	}

	return &Connection{
		Version:     2,
		LocalAddrs:  []string{localAddress},
		RemoteAddrs: remoteAddress,
		LocalPort:   localEndpoint.Port,
		RemotePort:  remoteEndpoint.Port,
		Encap:       true,
		KeyingTries: 0,
		Unique:      "replace",
		IfIdIn:      "%unique",
		IfIdOut:     "%unique",
		Local: Local{
			Auth:    "pubkey",
			Id:      localEndpoint.Id,
			Pubkeys: []string{localPublicKey},
		},
		Remote: Remote{
			Auth:    "pubkey",
			Id:      remoteEndpoint.Id,
			Pubkeys: []string{remotePublicKey},
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
