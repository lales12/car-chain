package config

import (    
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
)

type Config struct {
	Services map[string]Service `json:services`
}

type Service struct {
	Uuid 	string `json:uuid`
	Type 	string
}

func loadConfig() Config {
	fmt.Println("reading data")
	// Open our jsonFile
	jsonFile, err := os.Open("./service-config.json")
	// if we os.Open returns an error then handle it
	if err != nil {
		fmt.Println(err)
	}
	fmt.Println("Successfully Opened users.json")
	// defer the closing of our jsonFile so that we can parse it later on
	defer jsonFile.Close()

	byteValue, _ := ioutil.ReadAll(jsonFile)

	var config Config

	json.Unmarshal([]byte(byteValue), &config)

	return config;
}

func GetService(service string) Service{
	var config = loadConfig();

	serviceConfig := config.Services[service];
	serviceConfig.Type = service

	return serviceConfig
}
