import { NextPage } from 'next';
import { useQuery } from '@tanstack/react-query';
import api from '../src/lib/api';
import TodoList from '../src/components/TodoList';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import { useAppDispatch, useAppSelector } from '../src/store/hooks';
import { setUser } from '../src/store/slices/userSlice';

type Todo = { id: number; title: string; completed: boolean };

const fetchTodos = async (): Promise<Todo[]> => {
  const res = await api.get('/todos'); // if you don't have an API, use JSONPlaceholder or mock below
  return res.data;
};

const TodosPage: NextPage = () => {
  const dispatch = useAppDispatch();
  const user = useAppSelector((s) => s.user.user);

  const { data, isLoading, error, refetch } = useQuery<Todo[], Error>({
    queryKey: ['todos'],
    queryFn: fetchTodos,
    staleTime: 1000 * 30,
    retry: 1,
  });

  return (
    <Box>
      <Typography variant="h4" sx={{ mb: 2 }}>Todos</Typography>
      <Box sx={{ mb: 2 }}>
        <Button variant="contained" onClick={() => dispatch(setUser({ id: 'u1', name: 'Brandon' }))}>
          Set Demo User
        </Button>
        <Button sx={{ ml: 2 }} onClick={() => refetch()}>Refresh</Button>
      </Box>

      {isLoading && <Typography>Loading...</Typography>}
      {error && <Typography color="error">Failed to load todos</Typography>}
      {data && <TodoList todos={data} />}
    </Box>
  );
};

export default TodosPage;
