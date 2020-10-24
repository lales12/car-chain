package CreateCar

import (
	"fmt"

	"github.com/Shared/Domain/Bus"
)

type Handler struct{}

func (commandHandler Handler) CommandName() Bus.ICommand {
	return CreateCarCommand{}
}

func (commandHandler Handler) Handle(command Bus.ICommand) {
	fmt.Println("Dispatch create car")
	fmt.Println(command)
}
