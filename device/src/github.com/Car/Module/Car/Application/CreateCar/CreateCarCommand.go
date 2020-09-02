package CreateCar

type CreateCarCommand struct {
	id        string
	model     string
	plate     string
	createdAt string
}

func Command(
	id string,
	model string,
	plate string,
	createdAt string,
) CreateCarCommand {
	return CreateCarCommand{
		id:        id,
		model:     model,
		plate:     plate,
		createdAt: createdAt,
	}
}

func (command CreateCarCommand) Id() string {
	return command.id
}

func (command CreateCarCommand) Model() string {
	return command.model
}

func (command CreateCarCommand) Plate() string {
	return command.plate
}

func (command CreateCarCommand) CretedAt() string {
	return command.createdAt
}
