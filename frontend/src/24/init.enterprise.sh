### Enterprise Next.js Starter Guide
### https://copilot.microsoft.com/shares/pages/sNo6CMPwZVL2XfuBPXJYH
## Enterprise starter: Next.js + TypeScript + Redux Toolkit + MUI + React Query + Sentry — complete wiring and runnable code
# from project root

function init_libraries {
# Notes on choices:
# Next.js for file-based routing and SSR/SSG.
# Redux Toolkit for auditable global state and predictable reducers.
# React Query for server-state with caching, retries, background refetch.
# MUI for accessible, themeable component system; Emotion for styling engine.
# Sentry Next.js SDK initialized server + client for error reporting.
# Axios as HTTP client (replaceable).
npm install\
  @reduxjs/toolkit\
  react-redux\
  @tanstack/react-query\
  @tanstack/react-query-devtools\
  @mui/material\
  @mui/icons-material\
  @emotion/react @emotion/styled\
  @sentry/nextjs\
  axios
# dev
npm install -D eslint prettier
}

# ## Project layout key files shown
# echo "Project layout:
# components/
#   Layout.tsx
#   NavBar.tsx
#   ErrorBoundary.tsx
#   TodoList.tsx
# lib/
#   api.ts
#   sentry.ts
# pages/
#   _app.tsx
#   _document.tsx
#   index.tsx
#   todos.tsx
# src/
#   store/
#   index.ts
#   hooks.ts
#   slices/
#     uiSlice.ts
#     userSlice.ts
# theme/
#   theme.ts
# utils/
#   ssrCookie.ts
# "

# mkdir -p pages src/store src/slices lib components theme utils
# # Create files in pages/
# touch pages/_app.tsx pages/_document.tsx pages/index.tsx pages/todos.tsx
# # Create files in src/
# touch src/index.ts src/hooks.ts
# # Create files in src/slices/
# touch src/slices/uiSlice.ts src/slices/userSlice.ts
# # Create files in lib/
# touch lib/api.ts lib/sentry.ts
# # Create files in components/
# touch components/Layout.tsx components/NavBar.tsx components/ErrorBoundary.tsx components/TodoList.tsx
# # Create file in theme/
# touch theme/theme.ts
# # Create file in utils/
# touch utils/ssrCookie.ts

## Key runtime and environment configuration
cat >./next.config.js <<EOF
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  experimental: {
    // enable if you use server components later
  },
};

module.exports = nextConfig;
EOF

cat >.env.local <<EOF
NEXT_PUBLIC_SENTRY_DSN=https://examplePublicKey@o0.ingest.sentry.io/0
SENTRY_AUTH_TOKEN=exampleToken
EOF


## Sentry initialization - server + client
mkdir -p ./src/lib
cat >./src/lib/sentry.ts <<EOF
import * as Sentry from '@sentry/nextjs';

const SENTRY_DSN = process.env.NEXT_PUBLIC_SENTRY_DSN;

if (SENTRY_DSN) {
  Sentry.init({
    dsn: SENTRY_DSN,
    tracesSampleRate: 0.1, // tune for your app
    environment: process.env.NODE_ENV,
    release: process.env.NEXT_PUBLIC_VERCEL_GITHUB_COMMIT_SHA || undefined,
    // Add integrations and beforeSend if you want to filter events
  });
}

export default Sentry;
EOF


## Redux Toolkit wiring
mkdir -p ./src/store
cat >./src/store/index.ts <<EOF
import { configureStore } from '@reduxjs/toolkit';
import { useDispatch } from 'react-redux';
import uiReducer from './slices/uiSlice';
import userReducer from './slices/userSlice';

export const store = configureStore({
  reducer: {
    ui: uiReducer,
    user: userReducer,
  },
  devTools: process.env.NODE_ENV !== 'production',
  // Consider adding middleware for logging or serialization checks
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
export const useAppDispatch = () => useDispatch<AppDispatch>();
EOF

mkdir -p ./src/store
cat >./src/store/hooks.ts <<EOF
import { TypedUseSelectorHook, useSelector } from 'react-redux';
import type { RootState } from './index';

export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector;
EOF

mkdir -p ./src/store/slices
cat >./src/store/slices/uiSlice.ts <<EOF
import { createSlice, PayloadAction } from '@reduxjs/toolkit';

type UIState = {
  darkMode: boolean;
  sidebarOpen: boolean;
};

const initialState: UIState = { darkMode: false, sidebarOpen: false };

const uiSlice = createSlice({
  name: 'ui',
  initialState,
  reducers: {
    toggleDarkMode(state) { state.darkMode = !state.darkMode; },
    setSidebarOpen(state, action: PayloadAction<boolean>) { state.sidebarOpen = action.payload; },
  },
});

export const { toggleDarkMode, setSidebarOpen } = uiSlice.actions;
export default uiSlice.reducer;
EOF

mkdir -p ./src/store/slices
cat >./src/store/slices/userSlice.ts <<EOF
import { createSlice, PayloadAction } from '@reduxjs/toolkit';

type User = { id: string; name: string } | null;

const initialState: { user: User } = { user: null };

const userSlice = createSlice({
  name: 'user',
  initialState,
  reducers: {
    setUser(state, action: PayloadAction<User>) { state.user = action.payload; },
    clearUser(state) { state.user = null; },
  },
});

export const { setUser, clearUser } = userSlice.actions;
export default userSlice.reducer;
EOF

## React Query client and provider
mkdir -p ./src/lib
cat >./src/lib/api.ts <<EOF
import axios from 'axios';

const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_BASE_URL || '/api',
  headers: { 'Content-Type': 'application/json' },
  withCredentials: true,
});

export default api;
EOF

mkdir -p ./pages
cat >./pages/_app.tsx <<EOF
import type { AppProps } from 'next/app';
import { Provider as ReduxProvider } from 'react-redux';
import { store } from '../src/store';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';
import CssBaseline from '@mui/material/CssBaseline';
import { ThemeProvider } from '@mui/material/styles';
import theme from '../src/theme/theme';
import Layout from '../src/components/Layout';
import '../src/lib/sentry'; // ensure sentry initialized (client)
import { useState } from 'react';

export default function App({ Component, pageProps }: AppProps) {
  // create QueryClient per app instance; for SSR you may hydrate later
  const [queryClient] = useState(() => new QueryClient({
    defaultOptions: {
      queries: {
        retry: 1,
        refetchOnWindowFocus: false,
        staleTime: 1000 * 60, // 1 minute
      },
    },
  }));

  return (
    <ReduxProvider store={store}>
      <QueryClientProvider client={queryClient}>
        <ThemeProvider theme={theme}>
          <CssBaseline />
          <Layout>
            <Component {...pageProps} />
          </Layout>
          <ReactQueryDevtools initialIsOpen={false} />
        </ThemeProvider>
      </QueryClientProvider>
    </ReduxProvider>
  );
}
EOF

mkdir -p ./src/theme
cat >./src/theme/theme.ts <<EOF
import { createTheme } from '@mui/material/styles';

const theme = createTheme({
  palette: {
    mode: 'light',
    primary: { main: '#1976d2' },
  },
  components: {
    // global component overrides
  },
});

export default theme;
EOF

mkdir -p ./pages
cat >./pages/_document.tsx <<EOF
import Document, { Html, Head, Main, NextScript, DocumentContext } from 'next/document';
import createEmotionServer from '@emotion/server/create-instance';
import createCache from '@emotion/cache';
import theme from '../src/theme/theme';

function createEmotionCache() {
  return createCache({ key: 'css', prepend: true });
}

export default class MyDocument extends Document {
  static async getInitialProps(ctx: DocumentContext) {
    const originalRenderPage = ctx.renderPage;
    const cache = createEmotionCache();
    const { extractCriticalToChunks } = createEmotionServer(cache);

    ctx.renderPage = () =>
      originalRenderPage({
        enhanceApp: (App: any) => (props) => <App emotionCache={cache} {...props} />,
      });

    const initialProps = await Document.getInitialProps(ctx);
    const emotionStyles = extractCriticalToChunks(initialProps.html);
    const emotionStyleTags = emotionStyles.styles.map((style) => (
      <style
        data-emotion={\`\${style.key} \${style.ids.join(' ')}\`}
        key={style.key}
        // eslint-disable-next-line react/no-danger
        dangerouslySetInnerHTML={{ __html: style.css }}
      />
    ));

    return {
      ...initialProps,
      styles: [
        ...initialProps.styles as any,
        ...emotionStyleTags,
      ],
    };
  }

  render() {
    return (
      <Html lang="en">
        <Head>
          <meta name="theme-color" content={theme.palette.primary.main} />
        </Head>
        <body>
          <Main />
          <NextScript />
        </body>
      </Html>
    );
  }
}
EOF

mkdir -p ./src/components
cat >./src/components/Layout.tsx <<EOF
import { ReactNode } from 'react';
import Container from '@mui/material/Container';
import NavBar from './NavBar';

export default function Layout({ children }: { children: ReactNode }) {
  return (
    <>
      <NavBar />
      <Container maxWidth="lg" sx={{ mt: 4 }}>
        {children}
      </Container>
    </>
  );
}
EOF

mkdir -p src/components
cat >./src/components/NavBar.tsx <<EOF
import AppBar from '@mui/material/AppBar';
import Toolbar from '@mui/material/Toolbar';
import Typography from '@mui/material/Typography';
import Button from '@mui/material/Button';
import Link from 'next/link';
import { useAppDispatch, useAppSelector } from '../store/hooks';
import { toggleDarkMode } from '../store/slices/uiSlice';

export default function NavBar() {
  const dispatch = useAppDispatch();
  const darkMode = useAppSelector((s) => s.ui.darkMode);
  return (
    <AppBar position="static">
      <Toolbar>
        <Typography variant="h6" sx={{ flexGrow: 1 }}>
          Enterprise Demo
        </Typography>
        <Link href="/" legacyBehavior passHref><Button color="inherit">Home</Button></Link>
        <Link href="/todos" legacyBehavior passHref><Button color="inherit">Todos</Button></Link>
        <Button color="inherit" onClick={() => dispatch(toggleDarkMode())}>
          {darkMode ? 'Light' : 'Dark'}
        </Button>
      </Toolbar>
    </AppBar>
  );
}
EOF

mkdir -p ./src/components
cat >./src/components/ErrorBoundary.tsx <<EOF
 import React from 'react';
import * as Sentry from '@sentry/nextjs';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';

type Props = { children: React.ReactNode };

type State = { hasError: boolean };

export default class ErrorBoundary extends React.Component<Props, State> {
  state: State = { hasError: false };

  static getDerivedStateFromError() { return { hasError: true }; }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    Sentry.captureException(error, { extra: errorInfo });
  }

  render() {
    if (this.state.hasError) {
      return (
        <Box sx={{ p: 4 }}>
          <Typography variant="h4">Something went wrong</Typography>
          <Typography>Please try again or contact support.</Typography>
        </Box>
      );
    }
    return this.props.children;
  }
}
EOF


## Example page demonstrating React Query + Redux usage
mkdir -p ./pages
cat >./pages/todos.tsx <<EOF
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

  const { data, isLoading, error, refetch } = useQuery<Todo[]>(['todos'], fetchTodos, {
    staleTime: 1000 * 30, // 30s
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
EOF

mkdir -p ./src/components
cat >./src/components/TodoList.tsx <<EOF
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
EOF

## Example pages/api/todos.ts (mock)
mkdir -p ./pages/api
cat >./pages/api/todos.ts <<EOF
import type { NextApiRequest, NextApiResponse } from 'next';

const todos = [
  { id: 1, title: 'Write enterprise wiring', completed: false },
  { id: 2, title: 'Integrate React Query', completed: true },
];

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  res.status(200).json(todos);
}
EOF

## SSR / Hydration considerations (critical points)
# React Query: use dehydrate / Hydrate on SSR pages to avoid double-data fetches. Example: create a QueryClient on server in getServerSideProps, prefetchQuery, dehydrate, and pass dehydratedState via pageProps.
# Redux: Next.js hydration for Redux requires creating a store per request on server to avoid cross-request state. For many apps, keeping store client-only is acceptable; for server-derived initial state, implement wrapper using next-redux-wrapper or custom getServerSideProps store instantiation.
# MUI SSR: include Emotion SSR integration in _document (provided above) to avoid style mismatch flashes.
# Sentry: configure server + client DSNs correctly and sanitize user PII. Use Sentry.captureException in try/catch server handlers as well.

## Observability, error handling, and best operational practices
# Sentry: always attach environment, release, and user context when possible (Sentry.setUser).
# Logging: centralize important exceptions; avoid logging sensitive user data.
# Security: do not expose secrets in NEXT_PUBLIC_*. Store private DSNs server-side and forward as needed.
# Performance: enable React Query caching, server-side caching headers for SSR pages, and bundle-splitting for large pages.
# Accessibility: use MUI components and test with axe-core in CI.
