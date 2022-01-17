import { createStore } from 'vuex'

export interface State {
  login: string
}

export const user = createStore<State>({
  state: {
    login: 'kotsmile',
  },
})
