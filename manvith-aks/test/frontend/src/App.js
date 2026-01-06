import React, { useState } from "react";
import "./App.css";

function App() {
  const [selectedA, setSelectedA] = useState(null);
  const [selectedB, setSelectedB] = useState(null);
  const [response, setResponse] = useState(null);

  // Use relative paths - nginx will route to the correct backend
  const getApiUrl = (target) => {
    return `/api/${target}`;
  };

  async function uploadTo(target) {
    if (!selectedA && target === 'a') {
      alert('Please select a file first');
      return;
    }
    if (!selectedB && target === 'b') {
      alert('Please select a file first');
      return;
    }

    const form = new FormData();
    if (target === "a") form.append("image", selectedA);
    if (target === "b") form.append("image", selectedB);

    try {
      const res = await fetch(getApiUrl(target), { method: "POST", body: form });
      const data = await res.json();
      setResponse(data);
    } catch (error) {
      setResponse({ error: error.message });
    }
  }

  return (
    <div className="page">
      <h1>Multi-Backend Image-Upload (Kubernetes)</h1>

      <div className="grid">
        <div className="card">
          <h2>Backend A</h2>
          <input type="file" onChange={(e) => setSelectedA(e.target.files[0])} />
          <button onClick={() => uploadTo("a")}>Upload to A</button>
        </div>

        <div className="card">
          <h2>Backend B</h2>
          <input type="file" onChange={(e) => setSelectedB(e.target.files[0])} />
          <button onClick={() => uploadTo("b")}>Upload to B</button>
        </div>
      </div>

      <div className="response-section">
        <h2>Response:</h2>
        <pre>{response ? JSON.stringify(response, null, 2) : "No responses yet"}</pre>
      </div>
    </div>
  );
}

export default App;
