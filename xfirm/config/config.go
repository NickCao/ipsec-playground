package config

type Config struct {
	PrivateKey string     `json:"private_key"`
	Endpoints  []Endpoint `json:"endpoints"`
}

type Registy []Identity

type Identity struct {
	PublicKey string     `json:"public_key"`
	Endpoints []Endpoint `json:"endpoints"`
}

type Endpoint struct {
	Id      string `json:"id"`
	Family  string `json:"family"`
	Address string `json:"address"`
	Port    int    `json:"port"`
}
