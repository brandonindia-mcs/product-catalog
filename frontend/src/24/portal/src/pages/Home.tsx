import { useState } from 'react'
const Home = () => {
  const [count, setCount] = useState(0)
  return (
    <>
      <section style={{ padding: '2rem' }}>
        <h1>Welcome to My App</h1>
        <p>My multi-page React application. Navigate using the links above.</p>
        <p>Built with Vite, React, TypeScript, and deployed on Kubernetes with Node.js middleware.</p>
      </section>
      <div className="card">
        <button onClick={() => setCount((count) => count + 1)}>
          click-me count is {count}
        </button>
      </div>
    </>
  );
};

export default Home;
