import { expect } from 'chai';
import axios from 'axios';

describe('Chat API', () => {
  it('should respond with a message', async () => {
    const res = await axios.post('http://localhost:3001/chat', {
      message: 'Hello from test'
    });

    expect(res.status).to.equal(200);
    expect(res.data).to.have.property('reply');
  });
});
