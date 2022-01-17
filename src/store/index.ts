// store.ts
import { createStore } from 'vuex'
import { user } from './modules/user'

export interface State {}

export const store = createStore<State>({
  modules: {
    user,
  },
})
