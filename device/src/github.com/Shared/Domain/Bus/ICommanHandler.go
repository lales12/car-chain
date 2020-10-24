package Bus

type ICommandHandler interface {
	Handle(command ICommand)
	CommandName() ICommand
}
