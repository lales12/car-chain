package services

import (
	"log"
	"fmt"
	"github.com/paypal/gatt"
)
var data = "Initial value"

func UpdateKmData(newData string) {
	data = newData
}

func NewKmService(uuid string) *gatt.Service {

	s := gatt.NewService(gatt.MustParseUUID(uuid))
	
	s.AddCharacteristic(gatt.MustParseUUID("44fac9e0-c111-11e3-9246-0002a5d5c51b")).HandleReadFunc(
		func(rsp gatt.ResponseWriter, req *gatt.ReadRequest) {
			log.Println("read request")
			fmt.Fprintf(rsp, data)
	})

	s.AddCharacteristic(gatt.MustParseUUID("45fac9e0-c111-11e3-9246-0002a5d5c51b")).HandleWriteFunc(
		func(r gatt.Request, data []byte) (status byte) {
			log.Println("write request")
			return gatt.StatusSuccess
	})

	return s
}
