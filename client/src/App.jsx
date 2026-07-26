import { useEffect, useState, useRef } from "react";
import { ethers } from "ethers";
import abi from "../src/contractAbi/tokenMarketplaceAbi.json";
// import "./App.css";

function App() {
  const [address, setAddress] = useState("");
  const [contract, setContract] = useState(null);
  const [tokenPrice, setTokenPrice] = useState("");
  const [tokenPriceWei, setTokenPriceWei] = useState(0n);
  const inputTokenRef = useRef(null);

  async function connectWallet() {
    if (!window.ethereum) {
      alert("Ethereum Wallet is not installed");
    } else {
      const addresses = await window.ethereum.request({
        method: "eth_requestAccounts",
      });

      const contractAddress = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9";
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
      setTokenPriceWei(tokenPriceInWei);
      setTokenPrice(tokenPriceInEth);
    }
    getTokenPriceInEth();
  }, [contract]);

  async function buyTokensFromMarketplace(e) {
    e.preventDefault();
    if (!contract || tokenPriceWei === 0n) return;

    try {
      const numberOfTokens = BigInt(inputTokenRef.current.value);
      const amount = numberOfTokens * tokenPriceWei;
      const tx = await contract.buyTokensFromMarketplace(numberOfTokens, { value: amount });
      await tx.wait();
      alert("Tx Successful");
    } catch (error) {
      console.error(error);
      alert(error.shortMessage || error.reason || "Transaction failed");
    }
  }

  return (
    <>
      <button onClick={connectWallet}>Connect Wallet</button>
      <p>Connected Account: {address}</p>
      <p>Token Price(In Eth): {tokenPrice} </p>

      <form onSubmit={buyTokensFromMarketplace}>
        <input ref={inputTokenRef} placeholder="number of tokens"></input>
        <button type="submit"> Buy Tokens From Markeplace</button>
      </form>
    </>
  );
}

export default App;
