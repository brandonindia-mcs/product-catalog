import { useState } from 'react'
import reactLogo from '/react.svg'
import viteLogo from '/vite.svg'
const Home = () => {
  const [count, setCount] = useState(0)
  return (
    <>
      <div>
        <a href="https://vite.dev" target="_blank">
          <img src={viteLogo} className="logo" alt="Vite logo" />
        </a>
        <a href="https://react.dev" target="_blank">
          <img src={reactLogo} className="logo react" alt="React logo" />
        </a>
      </div>
      <section style={{ padding: '2rem' }}>
        <h1>Welcome to My App</h1>
        <p>This is the home page of your multi-page React application. Navigate using the links above.</p>
        <p>Built with Vite, React, TypeScript, and deployed on Kubernetes with a Node.js backend.</p>
      </section>
      <h1>Vite + React</h1>
      <div className="card">
        <button onClick={() => setCount((count) => count + 1)}>
          count is {count}
        </button>
      </div>
    </>
  );
};

export default Home;
