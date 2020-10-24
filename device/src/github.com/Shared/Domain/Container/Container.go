package Container

type Container struct {
	injections map[string]interface{}
}

func (container *Container) Init() {
	container.injections = make(map[string]interface{})
}

func (container *Container) Register(name string, handler interface{}) {
	container.injections[name] = handler
}

func (container *Container) Get(name string) interface{} {
	return container.injections[name]
}
