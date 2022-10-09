package config

type Config struct {
	Locals  []Local
	Remotes []Remote
}

type Local struct {
	LocalAddrs []string
	LocalPort  uint32
	PrivateKey []byte
	MTU        uint32
	Prefix     string
}

type Remote struct {
	RemoteAddrs []string
	RemotePort  uint32
	PublicKey   []byte
	MTU         uint32
	Name        string
}
