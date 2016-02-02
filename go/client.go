package main

import (
	"bufio"
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"golang.org/x/crypto/ssh/terminal"
	"os"
	"regexp"
)

func main() {
	// Connecting with a custom root-certificate set.

	const rootPEM = `
-----BEGIN CERTIFICATE-----
MIIDMjCCAhqgAwIBAgIJAJoNU3t5FM6NMA0GCSqGSIb3DQEBBQUAMBoxCzAJBgNV
BAYTAlVTMQswCQYDVQQIEwJNRDAeFw0xNjAxMzAyMzA4MjRaFw0xODExMTkyMzA4
MjRaMBoxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJNRDCCASIwDQYJKoZIhvcNAQEB
BQADggEPADCCAQoCggEBAMs+TIrb+Z1Di0f5LJPMm8LadiB0SO9+mhJxzo09LuZn
bGhKpVnlswBWEFiqTi+7Cz3hrjIhWj9Uk/LNoVnYT3oVt9/IgCiSy7X/VcJ4b8KR
vGBc44pXlNGaj4vFpyIsbEXZsZ9GNnxoytNzxfRdgTA2DkG/S7sXmsrFsPPwAQyj
svMF/arcQHWFcJ6EineWWgiRydnFzs6ShzV6qQTWcyhL7owPSDxzH832S/AFV9G4
viwgyDtjsLIccghkI8jy8G1gzyB9azV9GyI5CApGx+EIpmN6O43oIbNBYsIwf8+O
o6zrgNOft0Eq+lytXtmHtNP8o3FqhSW1gg3t2wxQ/K0CAwEAAaN7MHkwHQYDVR0O
BBYEFBmPhA8NTh6LFGDArvoyqsrQZAEsMEoGA1UdIwRDMEGAFBmPhA8NTh6LFGDA
rvoyqsrQZAEsoR6kHDAaMQswCQYDVQQGEwJVUzELMAkGA1UECBMCTUSCCQCaDVN7
eRTOjTAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBBQUAA4IBAQCvtH/SCsHxV177
egmr4cs32xJmSG0q0GIszZnGSREOM0uwHeo+Rig6boS+JuYaJGEJzFStn8QsG9aL
NNubuWIA6ZiP21Ji37XFUobzFGBplWVDbZ8ovAKaj/wW+gfvo+w3q2sZeOnftYRz
BQeFc7Dnla1qtuuCxNpLYzyXiEzRXbNIOLbHiMtocqLsymlov8G6AqANm5I3Cz0Q
K4XG6BQ+OvNc3oYl60R/emvjsIfdPZiBCREzsqPTq7x1VnQ8FFxtZHcQZHWetNmI
GRDUry86FUmwfdNX03vERMZFhrIf48r9nU8mroNmuC4gFpwpgkHGAun6qe/wdRGU
R3ezFj6G
-----END CERTIFICATE-----`

	// First, create the set of root certificates. For this example we only
	// have one. It's also possible to omit this in order to use the
	// default root set of the current operating system.
	roots := x509.NewCertPool()
	ok := roots.AppendCertsFromPEM([]byte(rootPEM))
	if !ok {
		panic("failed to parse root certificate")
	}

	conn, err := tls.Dial("tcp", "192.168.1.2:9953", &tls.Config{
		RootCAs:            roots,
		InsecureSkipVerify: true,
	})
	if err != nil {
		panic("failed to connect: " + err.Error())
	}

	// put terminal in raw mode
	oldState, err := terminal.MakeRaw(0)
	if err != nil {
		panic(err)
	}
	defer terminal.Restore(0, oldState)

	// create readwriter from Stdin / Stdout

	rw := bufio.NewReadWriter(bufio.NewReader(os.Stdin), bufio.NewWriter(os.Stdout))
	t := terminal.NewTerminal(rw, "> ")

	quitter := regexp.MustCompile("^q(uit)?$")

	for {
		msg, err := t.ReadLine()

		if err != nil {
			fmt.Println("failed to call ReadLine: " + err.Error())
			break
		}

		if quitter.MatchString(msg) {
			fmt.Println("quitting")
			break
		}

		conn.Write([]byte(msg + "\n"))
		fmt.Println(msg)
	}

	conn.Close()
}
