import { useEffect, useState } from "react";
import { ethers } from "ethers";
import abi from "../src/contractAbi/tokenMarketplaceAbi.json";
// import "./App.css";

function App() {
  const [address, setAddress] = useState("");
  const [contract, setContract] = useState("");
  const [tokenPrice, setTokenPrice] = useState("");

  async function connectWallet() {
    if (!window.ethereum) {
      alert("Ethereum Wallet is not installed");
    } else {
      const addresses = await window.ethereum.request({
        method: "eth_requestAccounts",
      });

      const contractAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();

      const contract = new ethers.Contract(contractAddress, abi, signer);
      setContract(contract);
      setAddress(addresses[0]);
    }
  }

  useEffect(() => {
    if (!contract) return;
    async function getTokenPriceInEth() {
      const tokenPriceInWei = await contract.getTokenPrice();
      const tokenPriceInEth = ethers.formatEther(tokenPriceInWei);
      setTokenPrice(tokenPriceInEth);
    }
    getTokenPriceInEth();
  }, [contract]);

  return (
    <>
      <button onClick={connectWallet}>Connect Wallet</button>
      <p>Connected Account: {address}</p>
      <p>Token Price(In Eth): {tokenPrice} </p>
    </>
  );
}

export default App;
