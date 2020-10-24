package FindCar

type findCarCommand struct {
	id string
}

func Query(id string) findCarCommand {
	return findCarCommand{
		id: id,
	}
}

func (command findCarCommand) Id() string {
	return command.id
}
