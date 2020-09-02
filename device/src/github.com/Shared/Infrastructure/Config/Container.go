package Config

import (
	"github.com/Car/Module/Car/Application/CreateCar"
	"github.com/Shared/Domain/Container"
	"github.com/Shared/Infrastructure/Bus"
)

// var container Container.Container

func Start() Container.Container {
	// if container != nil {
	// 	return Container
	// }

	container := Container.Container{}

	commandBus := Bus.CommandBus{}

	commandBus.Register(CreateCar.Handler{})

	container.Init()

	container.Register("command-bus", commandBus)

	return container
}
