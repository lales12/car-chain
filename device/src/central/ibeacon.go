package main

import (
	"encoding/binary"
	"encoding/hex"
	"errors"
	"strings"
)

type iBeacon struct {
	uuid  string
	major uint16
	minor uint16
}

func NewiBeacon(data []byte) (*iBeacon, error) {
	if len(data) < 25 || binary.BigEndian.Uint32(data) != 0x4c000215 {
		return nil, errors.New("Not an iBeacon")
	}
	beacon := new(iBeacon)
	beacon.uuid = strings.ToUpper(hex.EncodeToString(data[4:8]) + "-" + hex.EncodeToString(data[8:10]) + "-" + hex.EncodeToString(data[10:12]) + "-" + hex.EncodeToString(data[12:14]) + "-" + hex.EncodeToString(data[14:20]))
	beacon.major = binary.BigEndian.Uint16(data[20:22])
	beacon.minor = binary.BigEndian.Uint16(data[22:24])
	return beacon, nil
}
