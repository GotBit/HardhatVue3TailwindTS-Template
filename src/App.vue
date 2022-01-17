<template>
  <div class="w-full h-screen">
    <router-view />
  </div>
</template>

<script lang="ts" setup>
import { useStore } from 'vuex'
const store = useStore()
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  width: 100%;
  height: 100%;
}
</style>
