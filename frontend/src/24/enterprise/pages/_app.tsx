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
