import List from '@mui/material/List';
import ListItem from '@mui/material/ListItem';
import Checkbox from '@mui/material/Checkbox';
import ListItemText from '@mui/material/ListItemText';

export default function TodoList({ todos }: { todos: { id: number; title: string; completed: boolean }[] }) {
  return (
    <List>
      {todos.map((t) => (
        <ListItem key={t.id} disablePadding>
          <Checkbox checked={t.completed} />
          <ListItemText primary={t.title} />
        </ListItem>
      ))}
    </List>
  );
}
