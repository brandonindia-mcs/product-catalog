const About = () => {
  return (
    <section style={{ padding: '2rem' }}>
      <h1>About This Project</h1>
      <p>This application demonstrates a full-stack setup optimized for Node.js 24 and Kubernetes.</p>
      <ul>
        <li>Frontend: React + Vite + TypeScript</li>
        <li>Backend: Express.js on Node 24</li>
        <li>Deployment: Docker + Kubernetes</li>
      </ul>
      <p>Designed for audit-friendly CI/CD, health checks, and scalable architecture.</p>
    </section>
  );
};

export default About;
