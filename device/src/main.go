package main

import (
	"fmt"

	"github.com/Car/Module/Car/Application/CreateCar"
	"github.com/Car/Module/Car/Application/FindCar"
	"github.com/Shared/Infrastructure/Bus"
	"github.com/Shared/Infrastructure/Config"
)

func main() {
	carCommand := CreateCar.Command("1234234", "Seat Leon", "12345-MA", "New data")

	carQuery := FindCar.Query("12345")
	containerInstance := Config.Start()

	fmt.Println(containerInstance)
	commandBus := containerInstance.Get("command-bus").(Bus.CommandBus)

	commandBus.Dispatch(carCommand)

	fmt.Println(carCommand.Id())
	fmt.Println(carQuery.Id())

}
