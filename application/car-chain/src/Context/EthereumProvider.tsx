import React, { FC, ReactElement, createContext, useContext, useState } from "react";

import { Contract, providers, utils } from "ethers";
import { config } from "../configs/env.dev";

import EnjoyPassContract from "../../assets/contracts/SimpleStorage.json";

interface IEthereumContext {}

interface IProps {
    children: ReactElement;
}

const ethereumProvider = new providers.JsonRpcProvider(config.provider);

const EthereumContext = createContext<IEthereumContext>({});

export const EthereumProvider: FC<IProps> = (props: IProps) => {
    const [contract, setContract] = useState();

    useState(() => {
        setContract(new Contract(config.contractAddress, EnjoyPassContract.abi, ethereumProvider));
    }, []);

    return <EthereumContext.Provider value={{}}>{props.children}</EthereumContext.Provider>;
};

export const useEthereumContext = () => useContext(EthereumContext);
