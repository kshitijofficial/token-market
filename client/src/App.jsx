import { useState } from "react";
// import "./App.css";

function App() {
  const [address, setAddress] = useState("");

  async function connectWallet() {
    if (!window.ethereum) {
      alert("Ethereum Wallet is not installed");
    } else {

      const addresses = await window.ethereum.request({
        method: "eth_requestAccounts",
      });

      setAddress(addresses[0]);
    }
  }

  return (
    <>
      <button onClick={connectWallet}>Connect Wallet</button>
      <p>Connected Account: {address}</p>
    </>
  );
}

export default App;
