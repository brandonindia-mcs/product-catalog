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
