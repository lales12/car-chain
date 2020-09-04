package main

import (
	"fmt"
	"log"
	"config"
	"services"

	"github.com/paypal/gatt"
	"github.com/paypal/gatt/examples/option"
	"github.com/paypal/gatt/examples/service"
)

func startServices(configuredServices []config.Service) {
	d, err := gatt.NewDevice(option.DefaultServerOptions...)

	if err != nil {
		log.Fatalf("Failed to open device, err: %s", err)
	}

	d.Handle(
		gatt.CentralConnected(func(c gatt.Central) { fmt.Println("Connect: ", c.ID()) }),
		gatt.CentralDisconnected(func(c gatt.Central) { fmt.Println("Disconnect: ", c.ID()) }),
	)

	onStateChanged := func(d gatt.Device, s gatt.State) {
		fmt.Printf("State: %s\n", s)

		switch s {
		case gatt.StatePoweredOn:
			d.AddService(service.NewGapService("CarChain"))

			s1 := services.NewKmService(configuredServices[0].Uuid)
			
			d.AddService(s1)

			// Advertise device name and service's UUIDs.
			d.AdvertiseNameAndServices("CarChain", []gatt.UUID{s1.UUID()})

			// Advertise as an OpenBeacon iBeacon
			d.AdvertiseIBeacon(gatt.MustParseUUID("AA6062F098CA42118EC4193EB73CCEB6"), 1, 2, -59)

		default:
		}

		
	}

	d.Init(onStateChanged)
	select {}
}

func main() {
	configuredServices := []config.Service{
		config.GetService("km"),
	}


	fmt.Println(configuredServices[0].Type)	
	startServices(configuredServices)
}
