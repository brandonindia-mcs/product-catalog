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
