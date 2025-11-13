import type { NextApiRequest, NextApiResponse } from 'next';

const todos = [
  { id: 1, title: 'Write enterprise wiring', completed: false },
  { id: 2, title: 'Integrate React Query', completed: true },
];

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  res.status(200).json(todos);
}
