package main

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
	Pubkeys []string `vici:"pubkeys"`
}

type Remote struct {
	Auth    string   `vici:"auth"`
	Pubkeys []string `vici:"pubkeys"`
}

type Child struct {
	LocalTS     []string `vici:"local_ts"`
	RemoteTs    []string `vici:"remote_ts"`
	Mode        string   `vici:"mode"`
	StartAction string   `vici:"start_action"`
}

type Key struct {
	Type string `vici:"type"`
	Data string `vici:"data"`
}
