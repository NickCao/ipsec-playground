package config

type Config struct {
	Locals  []Local  `json:"locals"`
	Remotes []Remote `json:"remotes"`
}

type Local struct {
	LocalAddrs []string `json:"local_addrs"`
	LocalPort  uint32   `json:"local_port"`
	PrivateKey []byte   `json:"private_key"`
	MTU        uint32   `json:"mtu"`
	Prefix     string   `json:"prefix"`
}

type Remote struct {
	RemoteAddrs []string `json:"remote_addrs"`
	RemotePort  uint32   `json:"remote_port"`
	PublicKey   []byte   `json:"public_key"`
	MTU         uint32   `json:"mtu"`
	Name        string   `json:"name"`
}
