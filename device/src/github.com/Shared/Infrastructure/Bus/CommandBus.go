package Bus

import (
	"fmt"
	"reflect"

	"github.com/Shared/Domain/Bus"
)

type CommandBus struct {
	handlers map[string]Bus.ICommandHandler
}

func (commandBus CommandBus) Dispatch(command Bus.ICommand) {
	fmt.Println(reflect.TypeOf(command).String())
	commandHandlerName := reflect.TypeOf(command).String()

	handler, defined := commandBus.handlers[commandHandlerName]
	if defined {
		handler.Handle(command)
	}
}

func (commandBus *CommandBus) Register(handler Bus.ICommandHandler) {
	if commandBus.handlers == nil {
		commandBus.handlers = make(map[string]Bus.ICommandHandler)
	}
	fmt.Println("el command es")
	fmt.Println(reflect.TypeOf(handler.CommandName()))
	commandBus.handlers["asdf"] = handler
}

type ICommandHandler = Bus.ICommandHandler
