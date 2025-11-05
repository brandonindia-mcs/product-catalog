import axios from 'axios';

(async () => {
  try {
    const resp = await axios.post(
      'http://localhost:3001/chat',
      { message: 'Hello from node test' },
      { timeout: 15000 }
    );
    console.log('Response:', resp.data);
  } catch (err) {
    if (err.response) {
      console.error('Server error body:', err.response.data);
    } else {
      console.error('Request error:', err.message);
    }
  }
})();
