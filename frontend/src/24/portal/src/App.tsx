import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Navbar from './components/NavbarLayout';
import Home from './pages/Home';
import About from './pages/About';
import ProductList from './pages/ProductList';
import './App.css'

function App() {
  return (
    <>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Navbar />}>
            <Route index element={<Home />} />
            <Route path="about" element={<About />} />
            <Route path="catalog" element={<ProductList />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </>
  )
}

export default App
