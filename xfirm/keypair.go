package main

import (
	"crypto/ed25519"
	"crypto/rand"
	"crypto/x509"
	"encoding/pem"
)

func PrivateKeyToPublic(key string) (string, error) {
	block, _ := pem.Decode([]byte(key))
	privateKey, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		return "", nil
	}
	return PublicKeyToPem(privateKey.(ed25519.PrivateKey).Public())
}

func PrivateKeyToPem(key any) (string, error) {
	pkcs8, err := x509.MarshalPKCS8PrivateKey(key)
	if err != nil {
		return "", err
	}
	return string(pem.EncodeToMemory(&pem.Block{
		Type:  "PRIVATE KEY",
		Bytes: pkcs8,
	})), nil
}

func PublicKeyToPem(key any) (string, error) {
	pkix, err := x509.MarshalPKIXPublicKey(key)
	if err != nil {
		return "", err
	}

	return string(pem.EncodeToMemory(&pem.Block{
		Type:  "PUBLIC KEY",
		Bytes: pkix,
	})), nil
}

func GenerateKeypair() (string, string, error) {
	// openssl genpkey -algorithm ed25519 -outform PEM
	// openssl pkey -pubout
	publicKey, privateKey, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		return "", "", err
	}
	publicPem, err := PublicKeyToPem(publicKey)
	if err != nil {
		return "", "", err
	}
	privatePem, err := PrivateKeyToPem(privateKey)
	if err != nil {
		return "", "", err
	}
	return publicPem, privatePem, nil
}
