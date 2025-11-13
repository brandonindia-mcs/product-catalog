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
