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
    Sentry.captureException(error, {
      extra: {
        reactErrorInfo: {
          componentStack: errorInfo.componentStack,
        },
      },
    });
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
