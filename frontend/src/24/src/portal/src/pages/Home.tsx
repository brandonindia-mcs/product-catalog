import { useState } from 'react'
const Home = () => {
  const [count, setCount] = useState(0)
  return (
    <>
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
