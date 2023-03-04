package main

import (
	"crypto/ed25519"
	"crypto/rand"
	"crypto/x509"
)

func GenerateKeypair() ([]byte, []byte, error) {
	// openssl genpkey -algorithm ed25519 -outform PEM
	// openssl pkey -pubout
	pk, sk, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		return nil, nil, err
	}

	skb, err := x509.MarshalPKCS8PrivateKey(sk)
	if err != nil {
		return nil, nil, err
	}

	pkb, err := x509.MarshalPKIXPublicKey(pk)
	if err != nil {
		return nil, nil, err
	}

	return skb, pkb, nil
}
