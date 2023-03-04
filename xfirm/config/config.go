package config

type Registy []Remote

type Remote struct {
	Type string `json:"type"`
	Addr string `json:"addr"`
	Id   string `json:"id"`
}
